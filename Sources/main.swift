import PerfectLib
import PerfectHTTP
import PerfectHTTPServer
import RedisProvider

let redisListName = "tasks"
let removeKeyword = "DELETED"
var redisClient:Redis.TCPClient!

/*
 
 Does a LRANGE to redis datastore to get all the tasks we'v pushed
 
 */

func returnAllTasks(data: [String:Any]) throws -> RequestHandler {
    return { request, response in
        response.addHeader(HTTPResponseHeader.Name.accessControlAllowOrigin, value: "*")
        do{
            let redisData:Redis.Data? = try redisClient.command(.custom("LRANGE".bytes), [redisListName, "0", "-1"])
            let mappedArray = redisData?.array?.map({d in
                return d!.string!
            })
            if let array = mappedArray {
                try response.setBody(json: array)
                response.completed(status: .ok)
            }else{
                throw JSONConversionError.notConvertible(nil)
            }
        }catch {
            response.completed(status: .internalServerError)
        }
    }
}

/*
 
 Does a LPUSH to the task list with the POST task
 
 */

func saveNewTask(data: [String:Any]) throws -> RequestHandler {
    return { request, response in
        response.addHeader(HTTPResponseHeader.Name.accessControlAllowOrigin, value: "*")
        do {
            if let taskName = request.param(name: "task") {
                try redisClient.command(.custom("LPUSH".bytes), [redisListName, taskName])
                try redisClient.command(.custom("SAVE".bytes))
                response.completed(status: .ok)
            }else{
                throw JSONConversionError.notConvertible(nil)
            }
        }catch {
            response.completed(status: .internalServerError)
        }
    }
}

/*
 
 Does a LREM/LSET to remove the specific list index for the task item
 
 */

func deleteTask(data: [String:Any]) throws -> RequestHandler {
    return { request, response in
        response.addHeader(HTTPResponseHeader.Name.accessControlAllowOrigin, value: "*")

        do {
            if let param = request.urlVariables["id"] {
                try redisClient.command(.custom("LSET".bytes), [redisListName, param, removeKeyword])
                try redisClient.command(.custom("LREM".bytes), [redisListName, "1", removeKeyword])
                try redisClient.command(.custom("SAVE".bytes))
                response.completed(status: .ok)
            }else{
                throw JSONConversionError.notConvertible(nil)
            }
        }catch{
            print("\(error)")
            response.completed(status: .internalServerError)
        }
    }
}

/* 
 
 Tell the client which petitions can be made to this route
 
 */

func corsAllowDeleteTask(data: [String:Any]) throws -> RequestHandler {
    return {request, response in
        response.addHeader(HTTPResponseHeader.Name.accessControlAllowOrigin, value: "*")
        response.addHeader(HTTPResponseHeader.Name.accessControlAllowMethods, value: "DELETE")
        response.completed(status: .ok)
    }
}

/*
 
 Get last save timestamp
 
 */


func getRedisLastSave(data: [String:Any]) throws -> RequestHandler {
    return {request, response in
        response.addHeader(HTTPResponseHeader.Name.accessControlAllowOrigin, value: "*")
        do{
            let redisData:Redis.Data? = try redisClient.command(.custom("LASTSAVE".bytes))

            if let last = redisData?.int {
                try response.setBody(json: ["lastsave" :  last])
            }else{
                throw JSONConversionError.syntaxError
            }

            response.completed(status: .ok)
        }catch{
            response.completed(status: .internalServerError)
        }
    }
}

/*

 Server configuration
 
 */

let confData = [
	"servers": [
		[
			"name":"localhost",
			"port": 8080,
			"routes":[
				["method":"get", "uri":"/task", "handler":returnAllTasks],
				["method":"post", "uri":"/task", "handler": saveNewTask],
				["method":"delete", "uri":"/task/{id}", "handler": deleteTask],
                ["method":"options", "uri":"/task/{id}", "handler": corsAllowDeleteTask],
                ["method":"get", "uri":"/lastSave","handler":getRedisLastSave]

            ],
			"filters":[
				[
				"type":"response",
				"priority":"high",
				"name":PerfectHTTPServer.HTTPFilter.contentCompression,
				]
			]
		]
	]
]


/* Here we go... */
do {
    // Initialize the redis client
    redisClient = try Redis.TCPClient(hostname: "127.0.0.1", port: 6379, password: nil)
    // If redis launchs ok, then we launch the Perfect REST endpoint
    try HTTPServer.launch(configurationData: confData)
} catch {
	fatalError("\(error)")
}

