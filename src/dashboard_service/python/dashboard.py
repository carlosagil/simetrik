import grpc
from concurrent import futures
from simetrik.protos.v1 import simetrik_pb2, simetrik_pb2_grpc
import sys
from datetime import datetime
import logging

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

class DashboardServicer(simetrik_pb2_grpc.DashboardServiceServicer):
    def __init__(self):
        self.stats = {
            'total': 0,
            'matches': 0,
            'fraud_high_amount': 0,
            'fraud_duplicate': 0
        }

    def UpdateDashboard(self, request, context):
        """Handle incoming reconciliation responses"""
        self.process_response(request)
        return simetrik_pb2.DashboardResponse()  # Empty response

    def process_response(self, response):
        self.stats['total'] += 1
        
        if response.HasField('match'):
            self.stats['matches'] += 1
            result = "MATCH"
            details = f"Status: {simetrik_pb2.MatchStatus.Name(response.match.status)}"
            tx_id = response.match.transaction.transaction_id
        else:
            if response.fraud.reason == simetrik_pb2.FraudReason.HIGH_AMOUNT:
                self.stats['fraud_high_amount'] += 1
            elif response.fraud.reason == simetrik_pb2.FraudReason.DUPLICATE:
                self.stats['fraud_duplicate'] += 1
            
            result = "FRAUD DETECTED"
            details = f"Reason: {simetrik_pb2.FraudReason.Name(response.fraud.reason)}"
            tx_id = response.fraud.transaction.transaction_id

        # Print transaction details
        logging.info(f"\n[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}]")
        logging.info(f"Transaction ID: {tx_id}")
        logging.info(f"Result: {result}")
        logging.info(f"{details}")
        
        # Print statistics
        logging.info("\nStatistics:")
        logging.info(f"Total Transactions: {self.stats['total']}")
        logging.info(f"Matches: {self.stats['matches']}")
        logging.info(f"High Amount Frauds: {self.stats['fraud_high_amount']}")
        logging.info(f"Duplicate Frauds: {self.stats['fraud_duplicate']}")
        logging.info("--------------------")

def serve():
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
    simetrik_pb2_grpc.add_DashboardServiceServicer_to_server(
        DashboardServicer(), 
        server
    )
    server.add_insecure_port('[::]:50052')
    server.start()
    logging.info("Dashboard Service started on port 50052")
    try:
        server.wait_for_termination()
    except KeyboardInterrupt:
        server.stop(0)

if __name__ == '__main__':
    serve()
