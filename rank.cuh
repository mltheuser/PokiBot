/*
 *  Copyright 2016-2019 Henry Lee
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */

#ifndef PHEVALUATOR_RANK_H
#define PHEVALUATOR_RANK_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdbool.h>

enum rank_category {
  STRAIGHT_FLUSH = 1,
  FOUR_OF_A_KIND,
  FULL_HOUSE,
  FLUSH,
  STRAIGHT,
  THREE_OF_A_KIND,
  TWO_PAIR,
  ONE_PAIR,
  HIGH_CARD,
};

/*
 * Given a rank from 1 to 7462
 * Returns an integer from the enum rank_category
 */
enum rank_category get_rank_category(int rank);

/*
 * Given an enum rank_category
 * Returns a string description of the rank category, e.g. "Flush", "Full House"
 */
const char* describe_rank_category(enum rank_category category);

/*
 * Given a rank from 1 to 7462
 * Returns whether the rank is a flush
 */
bool is_flush(int rank);

#ifdef __cplusplus
} // closing brace for extern "C"
#endif

#ifdef __cplusplus

#include <vector>
#include <array>
#include <string>
#include "card.cuh"

namespace phevaluator {

class Rank {
 public:
  int value() const { return value_; }

  bool operator<(const Rank& other) const {
    return value_ >= other.value_;
  }

  bool operator<=(const Rank& other) const {
    return value_ > other.value_;
  }

  bool operator>(const Rank& other) const {
    return value_ <= other.value_;
  }

  bool operator>=(const Rank& other) const {
    return value_ < other.value_;
  }

  bool operator==(const Rank& other) const {
    return value_ == other.value_;
  }

  bool operator!=(const Rank& other) const {
    return value_ != other.value_;
  }

  bool isFlush() const {
    return is_flush(value_);
  }

  Rank(int value) : value_(value) {}
  Rank() {}

 private:
  int value_ = 0;
};

}

#endif

#endif