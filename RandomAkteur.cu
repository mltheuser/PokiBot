#include "RandomAkteur.cuh"
#include "Utils.cuh"
#include "RaiseBuckets.cuh"

#include <random>
#include <algorithm>
#include <iostream>
#include <cstring>

RandomAkteur::~RandomAkteur() {
    delete schablone;
}

RandomAkteur::RandomAkteur(std::string path) {
    schablone = Template::createDefaultTemplate(path);
}

std::pair<char, float> RandomAkteur::act(InformationSet* informationSet) {
    RoundPlayerInfo roundInfo = schablone->roundInfos.at(informationSet->round).at(informationSet->player);
    BucketFunction* bucketFunction = roundInfo.bucketFunction;
    vector<char> bucket = bucketFunction->getBucket(informationSet->playerCardsVisible);
    int bucketPosition = bucketFunction->getBucketPosition(bucket);

    int max = (bucketFunction->bucketList.size()) / (bucketFunction->size * 2);
    bool newBucket = bucketPosition >= max;

    if (newBucket) {
        return std::pair<char, float>('f', 0.f);
    }
    else {

        std::pair<int, GameState*> result = getCurrentNode(schablone, informationSet->actionHistory);
        int currentNodeWorklistIndex = result.first;
        GameState* currentGameState = result.second;

        if (currentNodeWorklistIndex < schablone->structureList->numStateNodes) {

            std::vector<std::pair<char, float>> currentActions = currentGameState->getActions();

            int actionInt = rand() % currentActions.size();

            delete currentGameState;

            return currentActions.at(actionInt);

        }
        else {
            // TODO
            // hier ist eigentlich schon spielende
        }

    }

    return std::pair<char, float>('O', 0.f);
}