#ifndef __BucketFunction__
#define __BucketFunction__

#include <string>
#include <vector>

class BucketFunction {
public:
    std::vector<char> bucketList;
    int round;
    size_t size;

    std::string folder;
    std::string fileName;

    /**
     * Die BucketFunction ist eine Sortierte (sortierte handkarten + sortierte flop karten + turn karte + river karte) Liste aller Möglicher Buckets einer BettingRound (0-3).
     * Die Position der Representation eines Bucktes in der Liste ist die Position an der der Bucket abgespeichert wurde.
     */
    BucketFunction(std::string folder, std::string fileName, int round, size_t size);

    void loadBucketFunction();

    void saveBucketFunction();

    int getBucketPosition(std::vector<char> bucket);

    std::vector<char> getBucket(std::vector<std::string> cards);

    std::vector<char> bucketCardsToNumbersNeglectStreetsAndFlushes(std::vector<std::string>* cards);
};

#endif