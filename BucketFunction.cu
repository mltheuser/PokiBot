#include "BucketFunction.cuh"
#include <algorithm>
#include <iterator>
#include <map>
#include <set>
#include <list>
#include <iostream>
#include <fstream>
#include <cstdio>

using std::string;
using std::vector;

std::map<char, int> ranksMap = {
        {'2',0},{'3',1},{'4',2},{'5',3},{'6',4},{'7',5},{'8',6},{'9',7},{'T',8},{'J',9},{'Q',10},{'K',11},{'A',12}
};

BucketFunction::BucketFunction(std::string folder, std::string fileName, int round, size_t size) {
    this->folder = folder,
    this->fileName = fileName;
    this->round = round;
    //Anzahl der Karten, nicht Anzahl der Chars
    this->size = size;

    loadBucketFunction();
}

void BucketFunction::loadBucketFunction() {
    std::ifstream t;
    int length;
    t.open(folder + "/" + fileName);      // open input file

    if (!t.good()) {
        //No file found
    }
    else {
        t.seekg(0, std::ios::end);    // go to the end
        length = t.tellg();           // report location (this is the length)
        t.seekg(0, std::ios::beg);    // go back to the beginning
        char* buffer = new char[length];    // allocate memory for a buffer of appropriate dimension
        t.read(buffer, length);       // read the whole file into the buffer
        t.close();

        bucketList.assign(buffer, buffer + length);
        delete[] buffer;
    }
}

void BucketFunction::saveBucketFunction() {
    if (bucketList.empty()) {
        throw "bucketList is empty despite the training being over";
    }
    char* bucketListArray = &bucketList[0];

    std::ofstream out(folder + "/" + fileName);
    out.write(bucketListArray, bucketList.size() * sizeof(char));
    out.close();
}

std::map<char, char> rankToClassified = {
       {'2','A'},{'3','A'},{'4','A'},{'5','B'},{'6','B'},{'7','B'},{'8','C'},{'9','C'},{'T','C'},{'J','D'},{'Q','D'},{'K','E'},{'A','E'}
};

char indexToRank[13] = { '2', '3', '4', '5', '6', '7', '8', '9', 'T', 'J', 'Q', 'K', 'A' };

std::vector<char> BucketFunction::bucketCardsToNumbersNeglectStreetsAndFlushes(std::vector<std::string>* cards) {
    //high card = drei klassen (A, B, C, D,  E)
    //Paare genauso
    //H: {A, K, Q, J}
    //M: {T, 9, 8}
    //L:{2, 3, 4, 5, 6, 7}

    std::map<char, int> rankCount = {
       {'2',0},{'3',0},{'4',0},{'5',0},{'6',0},{'7',0},{'8',0},{'9',0},{'T',0},{'J',0},{'Q',0},{'K',0},{'A',0}
    };

    std::map<char, int> suitCount = {
        {'c',0}, {'s',0}, {'h',0}, {'d',0}
    };

    for (int i = 0; i < size; i++) {
        rankCount.at(cards->at(i).at(0))++;
        suitCount.at(cards->at(i).at(1))++;
    }
    int maxSuit = std::max({ suitCount.at('c'),suitCount.at('s'),suitCount.at('h'),suitCount.at('d') });

    std::vector<char> bucket;
    bucket.reserve(size * (size_t)2);

    std::string bucketString;

    for (int i = 12; i >= 0; i--) {
        char rank = indexToRank[i];
        int count = rankCount.at(rank);
        if (count == 4) {
            char classifier = rankToClassified.at(rank);
            std::string s(1, classifier);
            //W = Platzwalter
            bucketString = "P4" + s + "W" + "WWWW";
            bucket.insert(bucket.end(), bucketString.begin(), bucketString.end());
        }
    }

    for (int i = 12; i >= 0; i--) {
        char rank = indexToRank[i];
        int count = rankCount.at(rank);
        if (count == 3) {
            char classifier = rankToClassified.at(rank);
            std::string s(1, classifier);
            //W = Platzwalter
            bucketString = "P3" + s + "W" + "WW";
            bucket.insert(bucket.end(), bucketString.begin(), bucketString.end());
        }
    }

    for (int i = 12; i >= 0; i--) {
        char rank = indexToRank[i];
        int count = rankCount.at(rank);
        if (count == 2) {
            char classifier = rankToClassified.at(rank);
            std::string s(1, classifier);
            //W = Platzwalter
            bucketString = "P2" + s + "W";
            bucket.insert(bucket.end(), bucketString.begin(), bucketString.end());
        }
    }

    for (int i = 12; i >= 0; i--) {
        char rank = indexToRank[i];
        int count = rankCount.at(rank);
        if (count == 1) {
            char classifier = rankToClassified.at(rank);
            std::string s(1, classifier);
            //W = Platzwalter
            bucketString = s + "W";
            bucket.insert(bucket.end(), bucketString.begin(), bucketString.end());
        }
    }

    if (round == 1) {
        if (maxSuit >= 3) bucket.back() = maxSuit;
    }
    else if (round == 2) {
        if (maxSuit >= 4) bucket.back() = maxSuit;
    }
    else if (round == 3) {
        if (maxSuit >= 5) bucket.back() = 5;
    }

    return bucket;
}

std::vector<char> BucketFunction::getBucket(std::vector<std::string> cards) {
    return bucketCardsToNumbersNeglectStreetsAndFlushes(&cards);
}

int BucketFunction::getBucketPosition(std::vector<char> bucket) {
    int i = 0;
    for (; i < bucketList.size() / (size * 2); i++) {
        bool matched = true;
        for (int j = 0; j < size * 2; j++) {
            if (bucket[j] != bucketList.at((i * size * 2) + j)) {
                matched = false;
                break;
            }
        }
        if (matched) return i;
    }
    return i;
}