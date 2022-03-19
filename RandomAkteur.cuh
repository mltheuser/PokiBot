#ifndef __RandomAkteur__
#define __RandomAkteur__

#include "Akteur.cuh"
#include "Template.cuh"

class RandomAkteur : public Akteur {
public:
    Template* schablone;

    ~RandomAkteur();
    RandomAkteur(std::string folder, std::string fileName);
    std::pair<char, float> act(InformationSet* informationSet) override;
};

#endif