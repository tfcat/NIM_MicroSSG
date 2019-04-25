import nre, strutils, os

proc die(msg : string): void =
    echo msg
    quit()

if paramCount() == 0:
    die "Not enough arguments"

let ddir = paramStr(1)
let workingDirectory = join([getAppDir(), "/", ddir, "/"]);

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

            if fileExists(join([workingDirectory, "/_includes/", captures[1]])) : 
                fileToRead = join([workingDirectory, "/_includes/", captures[1]])

            if fileToRead != "":
                result = replace(result, match.match, scanAndInsert(fileToRead, safetyIterCount+1))
    
    return result

# process each of these files as long as file path doesnt contain _result
for file in walkDir(workingDirectory):
    if not contains(file.path, "_result") and not contains(file.path, "_includes"):
        # process file and copy it to result
        let relFileName = replace(file.path, workingDirectory, "")
        echo join(["Compiling: ", relFileName])
        
        if not dirExists(join([workingDirectory, "_result/"])):
            createDir(join([workingDirectory, "_result/"]))
            
        writeFile(
            join([workingDirectory, "_result/", replace(file.path, workingDirectory, "")]), 
            scanAndInsert(file.path))

echo "done!"