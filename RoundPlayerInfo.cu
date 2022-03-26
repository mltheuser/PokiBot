#include "RoundPlayerInfo.cuh"

#include<iostream>

RoundPlayerInfo::RoundPlayerInfo(std::string folder, std::string fileName, int startPointTemplate, int elementSize, BucketFunction* bucketFunction, int round, int player) {
    this->startPointTemplate = startPointTemplate;
    this->elementSize = elementSize;
    this->bucketFunction = bucketFunction;

    size_t bucketListSize = bucketFunction->bucketList.size();
    size_t bucketSize = bucketFunction->size * 2;
    size_t bucketCount = bucketListSize / bucketSize;

    this->blueprintHandler = new BlueprintHandler(folder, fileName, round, player, bucketCount);
}