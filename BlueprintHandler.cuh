#ifndef __BlueprintHandler__
#define __BlueprintHandler__

#include <fstream>
#include <string>
#include <vector>

using std::vector;
using std::string;

class BlueprintHandler {
public:
    string path;
    std::ofstream ofStream;
    std::ifstream ifStream;


    BlueprintHandler(string folder, string fileName, int round, int player);

    bool blueprintExists(string path);
    void createBlueprint(string path);
    float* readPolicies(int pos, int size);
    void writePolicies(int pos, int size, float* policies);
    string getFileSize();
};

#endif