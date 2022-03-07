#include "BlueprintHandler.cuh"

#include <iostream>

std::string getPath(int round, int player) {
    return "blueprint" + std::to_string(round) + std::to_string(player);
}

BlueprintHandler::BlueprintHandler(int round, int player) {
    path = getPath(round, player);
    if (!blueprintExists(path)) {
        createBlueprint(path);
    }

    std::ofstream pOfStream(path, std::ios_base::binary | std::ios_base::out | std::ios_base::in);
    std::ifstream pIfStream(path, std::ios::binary | std::ios::in);
    ofStream = std::move(pOfStream);
    ifStream = std::move(pIfStream);
}

bool BlueprintHandler::blueprintExists(std::string path) {
    std::ifstream f(path.c_str());
    return f.good();
}

void BlueprintHandler::createBlueprint(std::string path) {
    char* empty = {};

    std::ofstream out(path);
    out.write(empty, 0);
    out.close();
}


std::vector<float> BlueprintHandler::readPolicies(int pos, int size) {
    if (!ifStream.is_open()) {
        std::cout << "Input stream nicht mehr offen!" << std::endl;
    }

    char* buffer = new char[size];
    ifStream.seekg(pos * size);
    ifStream.read(buffer, size);

    float* policies = (float*)buffer;

    return std::vector<float>(policies, policies + size);
}

/**
 * REQUIRE: Wenn für einen Spieler eine neue policy geschrieben wird, muss diese auch für den anderen Spieler geschrieben werden (geg. dann leer), da die Bucketfunktion diesselbe ist -> selber Index.
 */
void BlueprintHandler::writePolicies(int pos, int size, float* policies) {
    if (!ofStream.is_open()) {
        std::cout << "Output stream nicht mehr offen!" << std::endl;
    }

    ofStream.seekp(pos * size, std::ios_base::beg);

    char* charPolicies = (char*)policies;

    ofStream.write(charPolicies, size);

    ofStream.flush();
}