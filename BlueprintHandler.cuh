#ifndef __BlueprintHandler__
#define __BlueprintHandler__

#include <fstream>
#include <string>
#include <vector>

using std::vector;

class BlueprintHandler {
public:
    std::string path;
    std::ofstream ofStream;
    std::ifstream ifStream;


    BlueprintHandler(int round, int player);

    bool blueprintExists(std::string path);
    void createBlueprint(std::string path);
    std::vector<float> readPolicies(int pos, int size);
    void writePolicies(int pos, int size, float* policies);
};

#endif