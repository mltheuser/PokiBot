#include "BlueprintAkteur.cuh"
#include "Utils.cuh"

#include <random>
#include <algorithm>
#include <iostream>
#include <cstring>

BlueprintAkteur::~BlueprintAkteur() {
    delete schablone;
}

BlueprintAkteur::BlueprintAkteur(std::string path) {
    schablone = Template::createDefaultTemplate(path);
}

std::pair<char, float> BlueprintAkteur::act(InformationSet* informationSet) {
    RoundPlayerInfo roundInfo = schablone->roundInfos.at(informationSet->round).at(informationSet->player);
    BucketFunction* bucketFunction = roundInfo.bucketFunction;
    vector<char> bucket = bucketFunction->getBucket(informationSet->playerCardsVisible);
    int bucketPosition = bucketFunction->getBucketPosition(bucket);

    int max = (bucketFunction->bucketList.size()) / (bucketFunction->size * 2);
    bool newBucket = bucketPosition >= max;
    int size = roundInfo.elementSize;

    if (newBucket) {
        return std::pair<char, float>('f', 0.f);
    }
    else {
        float* reads = roundInfo.blueprintHandler->readPolicies(bucketPosition, size * sizeof(float));
        std::memcpy(schablone->cumulativeRegrets.at(informationSet->player) + roundInfo.startPointTemplate, reads, size * sizeof(float));
        delete[] reads;

        std::pair<int, GameState*> result = getCurrentNode(schablone, informationSet->actionHistory);
        int currentNodeWorklistIndex = result.first;
        GameState* currentGameState = result.second;

        if (currentNodeWorklistIndex < schablone->structureList->numStateNodes) {
            TrainingInitStruct* trainingInitStruct = initTrainingInitStruct(schablone, currentNodeWorklistIndex);

            vector<float> actions(trainingInitStruct->policy, trainingInitStruct->policy + trainingInitStruct->numChildren);

            free(trainingInitStruct->policy);

            float randomNumber = static_cast <float> (rand()) / static_cast <float> (RAND_MAX);
            float barrier = 0.f;
            int actionInt = trainingInitStruct->numChildren - 1;
            for (int i = 0; i < trainingInitStruct->numChildren; i++) {
                //setze barrier
                barrier += actions.at(i);
                if (barrier >= randomNumber) {
                    actionInt = i;
                    break;
                }
            }

            std::vector<std::pair<char, float>> currentActions = currentGameState->getActions();
            delete currentGameState;

            free(trainingInitStruct);
            return currentActions.at(actionInt);
        }
        else {
            // TODO
            // hier ist eigentlich schon spielende
        }

    }

    return std::pair<char, float>('O', 0.f);
}