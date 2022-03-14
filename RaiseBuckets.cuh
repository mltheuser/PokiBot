#ifndef __RaiseBuckets__
#define __RaiseBuckets__

#include <vector>
#include <tuple>
#include <algorithm>

//require aufsteigend sortiert
const std::vector<float> raiseSizes = { 1, 2, 4};

std::vector<std::pair<char, float>> getRaises();

float getRaise(float raise);

#endif