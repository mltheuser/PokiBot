#include "ManualAkteur.cuh"
#include "Utils.cuh"

#include <random>
#include <algorithm>
#include <iostream>
#include <cstring>

ManualAkteur::~ManualAkteur() {
    delete schablone;
}

ManualAkteur::ManualAkteur(std::string folder, std::string fileName) {
    schablone = Template::createDefaultTemplate(folder, fileName);
}

std::pair<char, float> ManualAkteur::act(InformationSet* informationSet) {
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

        if (currentNodeWorklistIndex < schablone->structureList->numStateNodes) {

            std::vector<std::pair<char, float>> currentActions = result.second->getActions();

            std::cout << "Karten: ";
            for (int i = 0; i < informationSet->playerCardsVisible.size(); i++) {
                std::cout << informationSet->playerCardsVisible.at(i);
            }
            std::cout << std::endl;

            std::cout << "Gegner Action: " << informationSet->actionHistory.back().first << std::endl;

            std::cout << "Possible Actions: ";
            for (int i = 0; i < currentActions.size(); i++) {
                std::cout << currentActions.at(i).first << "(" << i << ") ";
            }
            std::cout << std::endl;
            int action;
            std::cin >> action;

            delete result.second;
            return currentActions.at(action);

        }
        else {
            // TODO
            // hier ist eigentlich schon spielende
        }

    }

    return std::pair<char, float>('O', 0.f);
}