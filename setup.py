from setuptools import setup, find_packages


setup(name='skelly',
        version='1.0',
        packages=find_packages(),
        package_data={"conf": "skelly/conf/*"},
        zip_safe=False,
        entry_point={
            'console_scripts': [
                'create_shard_database = db-migration-script.create_shard_database'
            ]
        },
        install_requires=[])
