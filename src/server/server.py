import grpc
from concurrent import futures
from simetrik.protos.v1 import simetrik_pb2, simetrik_pb2_grpc
from datetime import datetime, timezone, timedelta
import logging
import os

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

# Get dashboard service address from environment variable
DASHBOARD_SERVICE_ADDRESS = os.getenv('DASHBOARD_SERVICE_ADDRESS', 'dashboard:50052')

class ReconciliationServicer(simetrik_pb2_grpc.ReconciliationServiceServicer):
    def __init__(self):
        self.timestamp_cache = {}
        self.duplicate_window = timedelta(minutes=300)
        # Create channel and stub for dashboard service
        self.dashboard_channel = grpc.insecure_channel(DASHBOARD_SERVICE_ADDRESS)
        self.dashboard_stub = simetrik_pb2_grpc.DashboardServiceStub(self.dashboard_channel)

    def _check_duplicate(self, transaction):
        """
        Check if a transaction is duplicate based on transaction_id and time window
        Returns True if duplicate is found
        """
        current_time = datetime.fromtimestamp(
            transaction.timestamp.seconds + transaction.timestamp.nanos/1e9,
            timezone.utc
        )
        
        tx_id = transaction.transaction_id
        
        if tx_id in self.timestamp_cache:
            existing_time = self.timestamp_cache[tx_id]
            time_diff = current_time - existing_time
            if time_diff <= self.duplicate_window:
                return True
            
        self.timestamp_cache[tx_id] = current_time
        return False

    def _forward_to_dashboard(self, response):
        """
        Forward the reconciliation response to the dashboard service
        """
        try:
            self.dashboard_stub.UpdateDashboard(response)
        except grpc.RpcError as e:
            logging.error(f"Failed to forward to dashboard: {e}")

    def ReconcileAndDetect(self, request_iterator, context):
        for transaction in request_iterator:
            response = None
            
            if self._check_duplicate(transaction):
                response = simetrik_pb2.ReconciliationResponse(
                    fraud=simetrik_pb2.FraudAlert(
                        transaction=transaction,
                        reason=simetrik_pb2.FraudReason.DUPLICATE
                    )
                )
            elif transaction.amount > 10000:
                response = simetrik_pb2.ReconciliationResponse(
                    fraud=simetrik_pb2.FraudAlert(
                        transaction=transaction,
                        reason=simetrik_pb2.FraudReason.HIGH_AMOUNT
                    )
                )
            else:
                response = simetrik_pb2.ReconciliationResponse(
                    match=simetrik_pb2.MatchResult(
                        transaction=transaction,
                        status=simetrik_pb2.MatchStatus.MATCHED
                    )
                )

            # Forward response to dashboard service
            self._forward_to_dashboard(response)
            
            # Yield response to original client
            yield response

    def __del__(self):
        """
        Clean up the gRPC channel when the servicer is destroyed
        """
        self.dashboard_channel.close()

def serve():
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
    simetrik_pb2_grpc.add_ReconciliationServiceServicer_to_server(
        ReconciliationServicer(), server
    )
    server.add_insecure_port('[::]:50051')
    server.start()
    logging.info("Server started on port 50051")
    try:
        server.wait_for_termination()
    except KeyboardInterrupt:
        server.stop(0)

if __name__ == '__main__':
    serve()
