#include "RoundPlayerInfo.cuh"

#include<iostream>

RoundPlayerInfo::RoundPlayerInfo(int startPointTemplate, int elementSize, BucketFunction* bucketFunction, int round, int player) {
    this->startPointTemplate = startPointTemplate;
    this->elementSize = elementSize;
    this->bucketFunction = bucketFunction;

    this->blueprintHandler = new BlueprintHandler(round, player);
}