#ifndef __GameMaster__
#define __GameMaster__

#include "BlueprintAkteur.cuh"
#include "RandomAkteur.cuh"
#include "Logger.cuh"

#include <string>

class GameMaster {
public:
    std::string folder;
    std::string fileName;

    GameMaster(std::string folder, std::string fileName);
    PlayResult* playBlueprintVersusBlueprint(int iterations);
    PlayResult* playBlueprintVersusRandom(int iterations);
    std::pair<int, float> play(Template* schablone, vector<std::string> cards, vector<Akteur*> akteure);
};

#endif