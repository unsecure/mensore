from fabric.api import *

def all_host():
	env.hosts = open('hosts.txt', 'r').readlines()

def check_date():
	run("date")

def check_hostname():
	run("hostname")

def check_disk():
	run("df -H")
