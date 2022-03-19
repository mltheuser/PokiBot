#include "BlueprintHandler.cuh"


#include "Logger.cuh"
#include <iostream>

std::string getPath(std::string folder, std::string fileName, int round, int player) {
    return folder + "/" + fileName + std::to_string(round) + std::to_string(player);
}

BlueprintHandler::BlueprintHandler(std::string folder, std::string fileName, int round, int player) {
    path = getPath(folder, fileName, round, player);
    if (!blueprintExists(path)) {
        createBlueprint(path);
    }

    std::ofstream pOfStream(path, std::ios_base::binary | std::ios_base::out | std::ios_base::in);
    std::ifstream pIfStream(path, std::ios::binary | std::ios::in);
    ofStream = std::move(pOfStream);
    ifStream = std::move(pIfStream);
}

bool BlueprintHandler::blueprintExists(string path) {
    std::ifstream f(path);
    return f.good();
}

void BlueprintHandler::createBlueprint(string path) {
    char* empty = {};

    std::ofstream out(path);
    out.write(empty, 0);
    out.close();
}


float* BlueprintHandler::readPolicies(int pos, int size) {
    if (!ifStream.is_open()) {
        Logger::throwRuntimeError("Input stream nicht mehr offen!");
    }

    char* buffer = new char[size];
    ifStream.seekg(pos * size);
    ifStream.read(buffer, size);

    float* policies = (float*)buffer;

    return policies;
}

/**
 * REQUIRE: Wenn für einen Spieler eine neue policy geschrieben wird, muss diese auch für den anderen Spieler geschrieben werden (geg. dann leer), da die Bucketfunktion diesselbe ist -> selber Index.
 */
void BlueprintHandler::writePolicies(int pos, int size, float* policies) {
    if (!ofStream.is_open()) {
        Logger::throwRuntimeError("Output stream nicht mehr offen!");
    }

    ofStream.seekp(pos * size, std::ios_base::beg);

    char* charPolicies = (char*)policies;

    ofStream.write(charPolicies, size);

    ofStream.flush();
}

std::string BlueprintHandler::getFileSize() {
    std::ifstream file(path, std::ios::binary | std::ios::ate);
    return std::to_string(file.tellg());
}