import PackageDescription

let package = Package(
	name: "RedisPerfectTodoAPI",
	targets: [],
	dependencies: [
		.Package(url: "https://github.com/PerfectlySoft/Perfect-HTTPServer.git", majorVersion: 2),
		.Package(url: "https://github.com/vapor/redis-provider.git", majorVersion: 2)
    ]
)
