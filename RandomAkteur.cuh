#ifndef __RandomAkteur__
#define __RandomAkteur__

#include "Akteur.cuh"
#include "Template.cuh"

class RandomAkteur : public Akteur {
public:
    Template* schablone;

    ~RandomAkteur();
    RandomAkteur(std::string path);
    std::pair<char, float> act(InformationSet* informationSet) override;
};

#endif