import re

fullRepoList = ['repo1', 'repo2']
list = ['item1', 'item2']


def reg_search(term):
    regex = re.compile('.*%s.*' % term)
    for i in fullRepoList:
        if re.match(regex, i):
            print(i)

def list_parse():
    for i in list:
        print('git clone https://URL.com/%s.git' % i)

if __name__ == '__main__':
    list_parse()