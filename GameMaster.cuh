#ifndef __GameMaster__
#define __GameMaster__

#include "BlueprintAkteur.cuh"
#include "RandomAkteur.cuh"

#include <string>

class GameMaster {
public:
    std::string path;

    GameMaster(std::string path);
    void playBlueprintVersusBlueprint(int iterations);
    void playBlueprintVersusRandom(int iterations);
    std::pair<int, float> play(Template* schablone, vector<std::string> cards, vector<Akteur*> akteure);
};

#endif