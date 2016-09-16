#!/usr/bin/env python3

class Vault(object):

    def __init__(self):
        self._config = {}
        self._load_config()


    def _load_config(self, config_file='site/vault.cfg'):
        '''Load site configuration from a bash-oriented config file.
        Method stolen from here: http://stackoverflow.com/questions/3503719/emulating-bash-source-in-python
        '''

        import os, subprocess, re, pprint
        if os.path.isfile(config_file):
            command = 'env -i bash -c " set -a && source {} && env"'.format(config_file)
            pattern = r'(?P<key>.*?)=(?P<value>.*)'
            for line in subprocess.getoutput(command).split("\n"):
                match = re.match(pattern, line)
                if match:
                    self._config[match.group('key')] = match.group('value')


    def execute(self, *commands):
        '''Execute vault with specified commands.'''

        import subprocess
        import os

        vault_command = 'vault {}'.format(' '.join([c for c in commands]))
        vault_env = os.environ
        vault_env['VAULT_ADDR'] = self._config['vault_host_addr']
        process = subprocess.Popen(vault_command,
                                   shell=True,
                                   universal_newlines=True,
                                   stdout=subprocess.PIPE,
                                   env=vault_env)
        response = [ line.rstrip("\n") for line in process.stdout ]
        print("\n".join(response))
        return response


    def auth(self):
        '''Authenticate using site-configured root token.'''

        self.execute('auth', self._config['vault_root_token'])


    def write(self, path, values):
        '''Write a set of values (supplied as dict) to the specified path.'''

        data = ' '.join(['{}={}'.format(k,v) for (k, v) in values.items()])
        self.execute('write', 'secret/{}'.format(path), data)


    def read(self, path):
        '''Read data from the specified path.'''
        self.execute('read', 'secret/{}'.format(path))


    def delete(self, path):
        '''Delete data from the specified path.'''
        self.execute('delete', 'secret/{}'.format(path))


def parse_secrets(vaulter, keys, secrets):

    values = {}
    for (k,v) in secrets.items():
        if isinstance(v, dict):
            keys.append(k)
            parse_secrets(vaulter, keys, v)
            keys.pop()

        else:
            values[k] = v
            path = '/'.join(keys)
            vaulter.delete('{}/{}'.format(path, k))

    if (len(values) > 0):
        path = '/'.join(keys)
        print(path)
        print(values)
        vaulter.delete(path)
        vaulter.write(path, values)
        vaulter.read(path)



def main():
    vaulter = Vault()
    vaulter.auth()

    import json
    secret_file = open('site/secrets.json', mode='r')
    secrets = json.load(secret_file)

    parse_secrets(vaulter, [], secrets)

if __name__ == "__main__":
    main()
