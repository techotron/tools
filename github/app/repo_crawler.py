import datetime
from github import Github
import re
import os
import base64


def check():
    print('hello world')


def print_log(etype, message):
    timestamp = datetime.datetime.now()
    print('[%s] - %s - %s' % (timestamp, etype, message))


def create_ghub():
    g = Github(base_url="https://github.bamtech.co/api/v3", login_or_token=os.getenv('GITHUB_API_RO'))
    return g


def list_repos(repo_filter):
    resp = []
    print_log('INFO', 'Attempting to list repos')
    ghub = create_ghub()

    regex = re.compile(repo_filter + '.*')
    repos = ghub.get_repos()

    for repo in repos:
        if re.match(regex, repo.full_name):
            resp.append(repo.full_name)
    return resp


def list_contents(repo_names):
    for repo_name in repo_names:
        print_log('INFO', 'Attempting to list contents of repo %s' % repo_name)
        ghub = create_ghub()
        repo = ghub.get_repo(repo_name)
        contents = repo.get_contents("")

        while len(contents) > 1:
            file_content = contents.pop(0)
            if file_content.type == "dir":
                contents.extend(repo.get_contents(file_content.path))
            else:
                print(file_content.path)
                try:
                    read_file = base64.b64decode(file_content.content)
                    print(read_file)
                except:
                    print('Error happened')



if __name__ == "__main__":
    print(os.getenv('GITHUB_API_RO'))