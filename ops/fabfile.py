from fabric.api import *

def all_host():
	env.hosts = open('hosts.txt', 'r').readlines()

def check_date():
	run("date")

def check_hostname():
	run("hostname")

def check_disk():
	run("df -H")

def check_mem():
	run("free -m")

def check_uptime():
	run("uptime")

def check_login():
	run("w")

def first_check():
	check_hostname()
	check_date()
	check_disk()
	check_mem()
	check_uptime()
	check_login()
