import grpc
from simetrik.protos.v1 import simetrik_pb2, simetrik_pb2_grpc
from google.protobuf.timestamp_pb2 import Timestamp
from datetime import datetime, timezone
import time
import random
import string
import sys
import logging

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

class TransactionGenerator:
    def __init__(self):
        self.transaction_counter = 0
        self.delay = 5  # Seconds between transactions
        self.currency_options = ["USD", "EUR", "GBP", "JPY", "COP"]  # Multiple currency support

    def generate_transaction_id(self, length=6):
        """Generate a unique transaction ID with timestamp"""
        timestamp = datetime.now().strftime("%Y%m%d%H%M")
        self.transaction_counter += 1
        return f"TX-{timestamp}-{self.transaction_counter:04d}-{''.join(random.choices(string.ascii_uppercase + string.digits, k=length))}"

    def generate_amount(self):
        """Generate random transaction amounts with different risk profiles"""
        rand = random.random()
        if rand < 0.55:
            return round(random.uniform(10.0, 5000.0), 2)
        elif rand < 0.75:
            return round(random.uniform(5000.01, 12000.0), 2)
        else:              # 25% high risk
            return round(random.uniform(12000.01, 50000.0), 2)

    def create_transaction(self):
        """Create a new transaction with random currency"""
        timestamp = Timestamp()
        timestamp.FromDatetime(datetime.now(timezone.utc))
        
        return simetrik_pb2.Transaction(
            transaction_id=self.generate_transaction_id(),
            amount=self.generate_amount(),
            currency=random.choice(self.currency_options),
            timestamp=timestamp
        )

    def generate_transactions(self):
        """Generate properly paced transaction stream"""
        while True:
            transaction = self.create_transaction()
            current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            print(f"\n[{current_time}] Generating transaction:")
            print(f"ID: {transaction.transaction_id}")
            print(f"Amount: {transaction.currency} {transaction.amount:.2f}")
            print(f"Next transaction in {self.delay} seconds...")
            yield transaction
            time.sleep(self.delay)

def run():
    print("Initializing Transaction Generator Service...")
    
    try:
        channel = grpc.insecure_channel('server:50051')
        stub = simetrik_pb2_grpc.ReconciliationServiceStub(channel)
        
        # print("\n=== Transaction Generator Started ===")
        # print("Configuration:")
        # print(f" - Transaction interval: 30 seconds")
        # print(f" - Currency options: USD, EUR, GBP, JPY, COP")
        # print(f" - Risk profile: 55% normal / 20% medium / 25% high")
        # print("=====================================")

        generator = TransactionGenerator()
        responses = stub.ReconcileAndDetect(generator.generate_transactions())

        # Real-time response processing
        for response in responses:
            current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            logging.info(f"Received transaction response: {response}")
            print("-" * 40)


    except KeyboardInterrupt:
        print("\nGracefully stopping transaction generator...")
        sys.exit(0)
    except Exception as e:
        print(f"\nCritical error: {str(e)}")
        sys.exit(1)

if __name__ == '__main__':
    run()