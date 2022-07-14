import Vapor

extension Request {
    public var clientRateLimiter: ClientRateLimiter {
        self.application.clientRateLimiter.for(req: self)
        /*.delegating(to: self.eventLoop).logging(to: self.logger).allocating(to: self.byteBufferAllocator)*/
    }
}

extension Application {
    public var clientRateLimiters: RateLimiterClients {
        .init(application: self)
    }
    
    public var clientRateLimiter: ClientRateLimiter {
        guard let makeClient = self.clientRateLimiters.storage.makeClient else {
            fatalError("No client configured. Configure with app.clients.use(...)")
        }
        return makeClient(self)
    }

    public struct RateLimiterClients {
        public struct Provider {
            let run: (Application) -> ()

            public init(_ run: @escaping (Application) -> ()) {
                self.run = run
            }
        }
        
        final class Storage {
            var makeClient: ((Application) -> ClientRateLimiter)?
            init() { }
        }
        
        struct Key: StorageKey {
            typealias Value = Storage
        }

        func initialize() {
            self.application.storage[Key.self] = .init()
        }
        
        public func use(_ provider: Provider) {
            provider.run(self.application)
        }

        public func use(_ makeClient: @escaping (Application) -> (ClientRateLimiter)) {
            self.storage.makeClient = makeClient
        }

        public let application: Application
        
        var storage: Storage {
            guard let storage = self.application.storage[Key.self] else {
                fatalError("Clients not initialized. Initialize with app.clients.initialize()")
            }
            return storage
        }
    }
    
}
