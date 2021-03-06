import Foundation

public typealias ChoreResult = (result: Int32, stdout: String, stderr: String)

private func string_trim(string: NSString!) -> String {
    return string.stringByTrimmingCharactersInSet(.whitespaceAndNewlineCharacterSet()) ?? ""
}

private func chore_task(command: String, arguments: [String]) -> ChoreResult {
    let task = NSTask()

    task.launchPath = command
    task.arguments = arguments

    if !(task.launchPath as NSString).absolutePath {
        task.launchPath = (chore_task("/usr/bin/which", [task.launchPath])).stdout
    }

    if !NSFileManager.defaultManager().fileExistsAtPath(task.launchPath) {
        return (255, "", String(format: "%@: launch path not accessible", task.launchPath))
    }

    let stderrPipe = NSPipe()
    task.standardError = stderrPipe
    let stderrHandle = stderrPipe.fileHandleForReading

    let stdoutPipe = NSPipe()
    task.standardOutput = stdoutPipe
    let stdoutHandle = stdoutPipe.fileHandleForReading

    task.launch()
    task.waitUntilExit()

    let stderr = string_trim(NSString(data: stderrHandle.readDataToEndOfFile(), encoding: NSUTF8StringEncoding)) ?? ""
    let stdout = string_trim(NSString(data: stdoutHandle.readDataToEndOfFile(), encoding: NSUTF8StringEncoding)) ?? ""

    return (task.terminationStatus, stdout, stderr)
}

prefix operator > {}

public prefix func > (command: String) -> ChoreResult {
    return chore_task(command, [String]())
}

public prefix func > (command: [String]) -> ChoreResult {
    switch command.count {
        case 0:
            return (0, "", "")
        case 1:
            return chore_task(command[0], [String]())
        default:
            break
    }

    return chore_task(command[0], Array(command[1..<command.count]))
}
