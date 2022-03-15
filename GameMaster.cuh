#ifndef __GameMaster__
#define __GameMaster__

#include "BlueprintAkteur.cuh"
#include "RandomAkteur.cuh"
//#include "Logger.cuh"

#include <string>

struct PlayResult {
    vector<int> winCounters = { 0, 0 };
    vector<float> payoffCounters = { 0.f, 0.f };
};

class GameMaster {
public:
    std::string path;

    GameMaster(std::string path);
    void playBlueprintVersusBlueprint(int iterations);
    PlayResult playBlueprintVersusRandom(int iterations);
    std::pair<int, float> play(Template* schablone, vector<std::string> cards, vector<Akteur*> akteure);
};

#endif