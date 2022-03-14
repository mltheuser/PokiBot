#include "RaiseBuckets.cuh"
#include <stdexcept>

std::vector<std::pair<char, float>> getRaises() {
    std::vector<std::pair<char, float>> raisePairs;
    raisePairs.reserve(raiseSizes.size());

    for (float raiseSize : raiseSizes) {
        raisePairs.push_back(std::pair<char, float>('r', raiseSize));
    }

    return raisePairs;
}

float getRaise(float raise) {
    if (raiseSizes.size() == 0) throw std::invalid_argument("getRaise is empty");

    std::vector<float>::const_iterator firstElementGreaterOrEquals = std::lower_bound(raiseSizes.begin(), raiseSizes.end(), raise);
    
    //falls keins gefunden -> firstElementGreaterOrEquals == raiseSizes.end()
    if (firstElementGreaterOrEquals == raiseSizes.end()) return raiseSizes.back();

    //falls es das erste ist -> firstElementGreaterOrEquals == raiseSizes.begin()
    if (firstElementGreaterOrEquals == raiseSizes.begin()) return raiseSizes.front();

    return *firstElementGreaterOrEquals - raise < raise - *(firstElementGreaterOrEquals - 1) ? *firstElementGreaterOrEquals : *(firstElementGreaterOrEquals - 1);
}