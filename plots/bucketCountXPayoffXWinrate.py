import matplotlib.pyplot as plt

class Record(object):
    def __init__(self, ITERATIONS, BUCKET_COUNT, FILE_SIZE, INIT_TIME, TRAIN_TIME, WIN_PERCENTAGE, LOOSE_PERCENTAGE, DRAW_PERCENTAGE, WIN_PERCENTAGE_NO_DRAW, NORMALIZED_PAYOFF, REMATCH_WIN_PERCENTAGE, REMATCH_LOOSE_PERCENTAGE, REMATCH_DRAW_PERCENTAGE, REMATCH_WIN_PERCENTAGE_NO_DRAW, REMATCH_NORMALIZED_PAYOFF):
        super(Record, self).__init__()
        self.ITERATIONS = ITERATIONS
        self.BUCKET_COUNT = BUCKET_COUNT
        self.FILE_SIZE = FILE_SIZE
        self.INIT_TIME = INIT_TIME
        self.TRAIN_TIME = TRAIN_TIME
        self.WIN_PERCENTAGE = WIN_PERCENTAGE
        self.LOOSE_PERCENTAGE = LOOSE_PERCENTAGE
        self.DRAW_PERCENTAGE = DRAW_PERCENTAGE
        self.WIN_PERCENTAGE_NO_DRAW = WIN_PERCENTAGE_NO_DRAW
        self.NORMALIZED_PAYOFF = NORMALIZED_PAYOFF
        self.REMATCH_WIN_PERCENTAGE = REMATCH_WIN_PERCENTAGE
        self.REMATCH_LOOSE_PERCENTAGE = REMATCH_LOOSE_PERCENTAGE
        self.REMATCH_DRAW_PERCENTAGE = REMATCH_DRAW_PERCENTAGE
        self.REMATCH_WIN_PERCENTAGE_NO_DRAW = REMATCH_WIN_PERCENTAGE_NO_DRAW
        self.REMATCH_NORMALIZED_PAYOFF = REMATCH_NORMALIZED_PAYOFF


#benchmarkFile = open('benchmarkcomparison_blueprint.txt', 'r')
preBenchmarkFile = open('pre_benchmarkcomparison_blueprint.txt', 'r')

preBenchmarkFile.readline()
preBenchmarkFile.readline()

#for x in range(11):
    #skip first two lines with description + next 9 lines cause of pre_benchmark
    #benchmarkFile.readline()


#LIST = [Record(*(line.split(','))) for line in benchmarkFile]

PRE_LIST = [Record(*(line.split(','))) for line in preBenchmarkFile]

### plotting
iterations = []

winrate = []
rematch_winrate = []
payoff = []
rematch_payoff = []
combined_winrate = []
combined_payoff = []

bucket_counts = []

for entry in PRE_LIST:
    iterations.append(int(entry.ITERATIONS) + 1000)

    winrate.append(float(entry.WIN_PERCENTAGE_NO_DRAW))
    payoff.append(float(entry.NORMALIZED_PAYOFF))
    rematch_winrate.append(float(entry.REMATCH_WIN_PERCENTAGE_NO_DRAW))
    rematch_payoff.append(float(entry.REMATCH_NORMALIZED_PAYOFF))
    combined_winrate.append((float(entry.WIN_PERCENTAGE_NO_DRAW) + float(entry.REMATCH_WIN_PERCENTAGE_NO_DRAW)) / 2)
    combined_payoff.append((float(entry.NORMALIZED_PAYOFF) + float(entry.REMATCH_NORMALIZED_PAYOFF)) / 2)

    bucket_counts.append(int(entry.BUCKET_COUNT))

#for entry in LIST:
    #iterations.append(int(entry.ITERATIONS) + 10000)

    #winrate.append(float(entry.WIN_PERCENTAGE_NO_DRAW))
    #payoff.append(float(entry.NORMALIZED_PAYOFF))
    #rematch_winrate.append(float(entry.REMATCH_WIN_PERCENTAGE_NO_DRAW))
    #rematch_payoff.append(float(entry.REMATCH_NORMALIZED_PAYOFF))
    #combined_winrate.append((float(entry.WIN_PERCENTAGE_NO_DRAW) + float(entry.REMATCH_WIN_PERCENTAGE_NO_DRAW)) / 2)
    #combined_payoff.append((float(entry.NORMALIZED_PAYOFF) + float(entry.REMATCH_NORMALIZED_PAYOFF)) / 2)

    #bucket_counts.append(int(entry.BUCKET_COUNT))

fig, axs = plt.subplots(2, 1)
fig.suptitle('Bucket Counts x winrate, payoff { 1, 5, 10, 25}')

axs[0].plot(bucket_counts, combined_winrate, label="Bucket Counts x Combined winrate")

#axs[0].set_xlabel('Bucket count')
axs[0].set_ylabel('Winrate')
axs[0].set_ylim([0.43, 0.51])
#axs[0].title('Bucket counts x combined winrate progression { 1, 5, 10, 25 }')
axs[0].legend()

axs[1].plot(bucket_counts, combined_payoff, label="Bucket Counts x Combined payoff")

axs[1].set_xlabel('Bucket count')
axs[1].set_ylabel('Payoff')
axs[1].set_ylim([-4.4, 0.65])
#axs[1].title('Bucket counts x combined payoff progression { 1, 5, 10, 25 }')
axs[1].legend()

plt.savefig('bucketCountXWRXPayoff.pdf')
plt.show()




