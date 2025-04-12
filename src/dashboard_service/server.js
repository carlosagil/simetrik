const grpc = require('@grpc/grpc-js');
const protoLoader = require('@grpc/proto-loader');
const express = require('express');
const WebSocket = require('ws');
const path = require('path');
const net = require('net');

// Configuration
const GRPC_PORT = process.env.GRPC_PORT || 50052;
const WEB_PORT = process.env.WEB_PORT || 3000;
const WS_PORT = process.env.WS_PORT || 8080;

// gRPC Server Setup
const packageDefinition = protoLoader.loadSync(
    path.join(__dirname, 'protos/simetrik.proto'),
    {
        keepCase: true,
        longs: String,
        enums: String,
        defaults: true,
        oneofs: true,
        includeDirs: [path.join(__dirname, 'protos')],
        enums: Object // Change this to get enum values as objects
    }
);

const proto = grpc.loadPackageDefinition(packageDefinition).simetrik;

// Log available enums for debugging
// console.log('Available Enums:', {
//     FraudReason: proto.FraudReason,
//     MatchStatus: proto.MatchStatus
// });

const grpcServer = new grpc.Server();

// Web Server Setup
const app = express();
const wss = new WebSocket.Server({ port: WS_PORT });

// State Management
let isGrpcReady = false;
const stats = {
    total: 0,
    matches: 0,
    fraudHighAmount: 0,
    fraudDuplicate: 0
};

// Enum mappings
const FraudReasonEnum = {
    HIGH_AMOUNT: 1,
    DUPLICATE: 2
};

const MatchStatusEnum = {
    EXACT: 1,
    PARTIAL: 2
};

// gRPC Service Implementation
grpcServer.addService(proto.DashboardService.service, {
    updateDashboard: (call, callback) => {
        try {
            const response = call.request;
            stats.total++;

            if (response.fraud) {
                switch (response.fraud.reason) {
                    case FraudReasonEnum.HIGH_AMOUNT:
                        stats.fraudHighAmount++;
                        break;
                    case FraudReasonEnum.DUPLICATE:
                        stats.fraudDuplicate++;
                        break;
                    default:
                        console.warn(`Unknown fraud reason: ${response.fraud.reason}`);
                }
            } else {
                stats.matches++;
            }

            broadcastUpdate(response);
            callback(null, { success: true });
        } catch (error) {
            console.error('Error processing update:', error);
            callback({
                code: grpc.status.INTERNAL,
                details: 'Failed to process dashboard update'
            });
        }
    }
});

// Health Endpoints
app.get('/health', (req, res) => res.status(200).json({ status: 'ok' }));
app.get('/ready', (req, res) => {
    res.status(isGrpcReady ? 200 : 503).json({
        grpc: isGrpcReady,
        websocket: wss.clients.size > 0
    });
});

// Server Initialization
function startServers() {
    const portCheckServer = net.createServer();
    portCheckServer.once('error', (err) => {
        if (err.code === 'EADDRINUSE') {
            console.error(`Port ${GRPC_PORT} already in use`);
            process.exit(1);
        }
    });

    portCheckServer.listen(GRPC_PORT, () => {
        portCheckServer.close(() => {
            grpcServer.bindAsync(
                `0.0.0.0:${GRPC_PORT}`,
                grpc.ServerCredentials.createInsecure(),
                (err, port) => {
                    if (err) {
                        console.error('gRPC server failed to start:', err);
                        process.exit(1);
                    }
                    console.log(`gRPC server listening on port ${port}`);
                    isGrpcReady = true;
                }
            );
        });
    });

    app.use(express.static(path.join(__dirname, 'public')));
    app.listen(WEB_PORT, () => {
        console.log(`Web server listening on port ${WEB_PORT}`);
        console.log(`WebSocket server listening on port ${WS_PORT}`);
    });
}

// WebSocket Handling
function broadcastUpdate(response) {
    try {
        const payload = JSON.stringify({
            type: 'update',
            stats: { ...stats },
            transaction: serializeTransaction(response)
        });

        wss.clients.forEach(client => {
            if (client.readyState === WebSocket.OPEN) {
                client.send(payload);
            }
        });
    } catch (error) {
        console.error('Error broadcasting update:', error);
    }
}

function getFraudReasonName(reason) {
    switch (reason) {
        case FraudReasonEnum.HIGH_AMOUNT:
            return 'HIGH_AMOUNT';
        case FraudReasonEnum.DUPLICATE:
            return 'DUPLICATE';
        default:
            return 'UNKNOWN';
    }
}

function getMatchStatusName(status) {
    switch (status) {
        case MatchStatusEnum.EXACT:
            return 'EXACT';
        case MatchStatusEnum.PARTIAL:
            return 'PARTIAL';
        default:
            return 'UNKNOWN';
    }
}

function serializeTransaction(response) {
    try {
        const tx = response.fraud ? response.fraud.transaction : response.match.transaction;
        
        return {
            id: tx.transaction_id,
            amount: tx.amount,
            currency: tx.currency,
            timestamp: tx.timestamp.seconds * 1000,
            result: response.fraud ? 'FRAUD' : 'MATCH',
            reason: response.fraud ? 
                getFraudReasonName(response.fraud.reason) : 
                getMatchStatusName(response.match.status)
        };
    } catch (error) {
        console.error('Error serializing transaction:', error);
        return {
            id: 'ERROR',
            amount: 0,
            currency: 'UNKNOWN',
            timestamp: Date.now(),
            result: 'ERROR',
            reason: 'SERIALIZATION_ERROR'
        };
    }
}

// Start Application
startServers();

// Graceful Shutdown
process.on('SIGTERM', () => {
    console.log('Shutting down servers...');
    grpcServer.tryShutdown(() => {
        wss.close();
        process.exit(0);
    });
});
