r = open("insertion.sql", "r")

i = 0

for line in r:
    i+=1

r.close()

r = open("insertion.sql", "r")


for h in range(10):
    f = open(f"insertion_all_{h}.sql", 'w')
    for j, line in enumerate(r):
        if j == i // 10:
            break
        f.write(line)
    f.close
    if h == 9:
        for line in r:
            f = open(f"insertion_all_{h}.sql", 'w')
            f.write(line)
            f.close()


# for line in r:
#     f = open(f"insertion_all_{8}.sql", 'w')
#     f.write(line)
#     f.close()