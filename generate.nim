import nre, strutils, os

proc die(msg : string): void =
    echo msg
    quit()

if paramCount() == 0:
    die "Not enough arguments"

let ddir = paramStr(1)
let workingDirectory = join([getCurrentDir(), "/", ddir, "/"]);

# check directory
if not dirExists(workingDirectory):
    die "Not a valid directory"

proc scanAndInsert(filePath : string, safetyIterCount : int = 0): string =
    if safetyIterCount >= 10:
        die("Nested include limit reached, please fix your recursion!")

    let fileContent = readFile(filePath)
    var result = fileContent
    let matchWithinBraces = re"{{([\sa-zA-Z0-9\.\\\/]+)}}"

    for match in fileContent.findIter(matchWithinBraces):
        var cap = captures(match)[0]
        var captures = splitWhitespace(cap)
        if captures[0] == "include":
            var fileToRead = ""

            if fileExists(join([workingDirectory, "/", captures[1]])):
                fileToRead = join([workingDirectory, "/", captures[1]])

            if fileExists(join([workingDirectory, "/_include/", captures[1]])) : 
                fileToRead = join([workingDirectory, "/_include/", captures[1]])

            if fileToRead != "":
                result = replace(result, match.match, scanAndInsert(fileToRead, safetyIterCount+1))
    
    return result

# process each of these files as long as file path doesnt contain _result
proc processDir(dir : string): void =
    for file in walkDir(dir):
        if not contains(file.path, "_result") and not contains(file.path, "_include"):
            # process file and copy it to result
            let relFileName = replace(file.path, workingDirectory, "")
            
            if not dirExists(join([workingDirectory, "_result/"])):
                createDir(join([workingDirectory, "_result/"]))
            
            var filePath = join([workingDirectory, "_result/", relFileName])
            
            if contains(relFileName, ".html"):
                echo join(["Compiling: ", relFileName])
                writeFile(filePath, scanAndInsert(file.path))
            elif not dirExists(file.path):
                copyFile(filePath, file.path)
            else:
                createDir(filePath)
                processDir(file.path)

processDir(workingDirectory)

echo "done!"
