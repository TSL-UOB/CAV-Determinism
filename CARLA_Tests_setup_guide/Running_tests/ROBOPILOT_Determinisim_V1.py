#!/usr/bin/env python

############################################################################################
############################ ROBOPILOT UE4 determinisim script  ############################
############################   Trustworthy Systems Laboratory   ############################ 
############################       University Of Bristol        ############################     
############################################################################################


import glob
import os
import sys

try:
	sys.path.append(glob.glob('../carla/dist/carla-*%d.%d-%s.egg' % (
		sys.version_info.major,
		sys.version_info.minor,
		'win-amd64' if os.name == 'nt' else 'linux-x86_64'))[0])
except IndexError:
	pass

import carla
import argparse
import logging
import random
import numpy as np
import math
import csv
import time
import pandas as pd
import live_plotter as lv   # Custom live plotting library


# Script level imports
sys.path.append('../carla')
from agents.navigation.roaming_agent import RoamingAgent
from agents.navigation.basic_agent import BasicAgent
from numpy import zeros


import ROBOPILOT_agentsController

from decimal import *

#=============================================
#===Declerations 
#=============================================


#===Input directory ==========================
INPUT_FOLDER             = os.path.dirname(os.path.realpath(__file__)) +\
							'/ExperimentInputs/'

# INPUT_FILENAME           = 'Determinisim_TEST_Cars.txt'

#===Output directory =========================
RESULTS_OUTPUT_FOLDER    = os.path.dirname(os.path.realpath(__file__)) +\
							'/ExperimentResutls/'

# RESULTS_OUTPUT_FILENAME  = 'TEST_ID_001.txt'

#===Ploting configurable parameters ==========
FIGSIZE_X_INCHES   = 8      # x figure size of feedback in inches
FIGSIZE_Y_INCHES   = 8      # y figure size of feedback in inches
PLOT_LEFT          = 0.1    # in fractions of figure width and height
PLOT_BOT           = 0.1    
PLOT_WIDTH         = 0.8
PLOT_HEIGHT        = 0.8
PLOTTING_FLAG      = False


#===Interpolation configurable parameters ====
INTERP_LOOKAHEAD_DISTANCE = 2   # lookahead in meters
INTERP_DISTANCE_RES       = 0.01 # distance between interpolated points


#===Logging configurable parameters ==========
LOGGING_TIME_INCREMENT   = 0.1
REPEAT_TESTS             = True
# NUMBER_OF_TEST_REPEATS   = 1000
# if REPEAT_TESTS != True or NUMBER_OF_TEST_REPEATS <=0 :
# 	NUMBER_OF_TEST_REPEATS = 1



#===Other declerations =======================
WAIT_TIME_BEFORE_START    = 0#5.00  
# KILL_TEST_TIME_THRESHOLD  = 25      # in seconds   (cars/collision/people = 25; cars/collision = ---; cars = ---)  

isWalker   = False
isVehicle  = False

STOPPING_DISTANCE = 5
STOPPING_SPEED    = 0.1




#===Library of types of agents ===============
AV_list        = ["Arrival", "CAPRI"]

Cars_list      = ["vehicle.ford.mustang", "vehicle.audi.a2", "vehicle.audi.tt", "vehicle.citroen.c3", "vehicle.bmw.grandtourer", "vehicle.bmw.isetta", "vehicle.mercedes-benz.coupe",
				  "vehicle.toyota.prius", "vehicle.dodge_charger.police", "vehicle.nissan.patrol", "vehicle.nissan.micra", "vehicle.seat.leon", "vehicle.lincoln.mkz2017", "vehicle.tesla.model3",
				  "vehicle.chevrolet.impala", "vehicle.mini.cooperst", "vehicle.jeep.wrangler_rubicon"]

Ped_list       = ["walker.pedestrian.0001", "walker.pedestrian.0002", "walker.pedestrian.0003", "walker.pedestrian.0004", "walker.pedestrian.0005", "walker.pedestrian.0006", "walker.pedestrian.0007",
				  "walker.pedestrian.0008", "walker.pedestrian.0009", "walker.pedestrian.0010", "walker.pedestrian.0011", "walker.pedestrian.0012", "walker.pedestrian.0013", "walker.pedestrian.0014" ]

HEV_list       = ["vehicle.volkswagen.t2", "vehicle.carlamotors.carlacola"]

Bicycle_list   = ["vehicle.gazelle.omafiets", "vehicle.diamondback.century", "vehicle.bh.crossbike"]

Motorcyle_list = ["vehicle.kawasaki.ninja", "vehicle.yamaha.yzf", "vehicle.harley-davidson.low rider"]



#=============================================
#===Functions
#=============================================

def Ticking(world,frame):
	# Tick
	world.tick()

	# Get world snapshot   
	world_snapshot = world.get_snapshot()
	ts             = world_snapshot.timestamp

	if frame is not None:
		if ts.frame_count != frame + 1:
			logging.warning('frame skip!')

	frame          = ts.frame_count

	return ts, frame

def Create_Output_Dir(output_folder):
	if not os.path.exists(output_folder):
		os.makedirs(output_folder)


def Read_Test_File(INPUT_FOLDER,INPUT_FILENAME): 
	file_name = os.path.join(INPUT_FOLDER, INPUT_FILENAME)
	Data_file = file_name
	df = pd.read_csv(Data_file, delimiter=',')

	return df


def Write_Log_File(RESULTS_OUTPUT_FILENAME,RESULTS_OUTPUT_FOLDER,repeatNo_list, agentNo_list, agentID_list, agentType_list, agentTypeNo_list, time_list, fps_list, x_list, y_list, z_list, yaw_list):
	Create_Output_Dir(RESULTS_OUTPUT_FOLDER)
	file_name = os.path.join(RESULTS_OUTPUT_FOLDER, RESULTS_OUTPUT_FILENAME)


	with open(file_name, 'w') as trajectory_file: 
		trajectory_file.write('repeatNo, agentNo, agentID, agentType, agentTypeNo, time, fps, x, y, z, yaw \n')
		for i in range(len(agentID_list)):
			trajectory_file.write('%d, %d, %d, %s, %d, %3.3f, %3.3f, %3.3f, %3.3f, %3.3f, %3.3f\n' %\
								(repeatNo_list[i], agentNo_list[i], agentID_list[i], agentType_list[i], agentTypeNo_list[i], time_list[i], fps_list[i], x_list[i], y_list[i], z_list[i], yaw_list[i]))
	print('Log file SUCCESSFULLY generated!')

def Determinisim_PostProcess(repeatNo_list, agentNo_list, agentID_list, agentType_list, agentTypeNo_list, time_list, fps_list, x_list, y_list, z_list, yaw_list):
	# Create dataframe
	df = pd.DataFrame(list(zip(repeatNo_list, agentNo_list, agentID_list, agentType_list, agentTypeNo_list, time_list, fps_list, x_list, y_list, z_list, yaw_list)), 
			   columns =["repeatNo", "agentNo", "agentID", "agentType", "agentTypeNo", "time", "fps", "x", "y", "z", "yaw"]) 

	# Find number of exclusive agents and tests
	agentIDs = np.unique(agentID_list)
	Agents   = np.unique(agentNo_list)
	nAgents  = len(Agents)
	nRepeats = max(repeatNo_list)
	maxTime  = max(time_list)
	timeStep = 0.1

	# Store raw, non-interpolated data (T,X,Y) and variance
	rawData  = np.zeros((nRepeats,nAgents,3,round(maxTime/timeStep)))

	# For each agent get (T,X,Y) then variance
	rN = df["repeatNo"].astype(np.int)
	aN = df["agentNo"].astype(np.int)
	for i in range(nRepeats):
		for j in range(nAgents):
			tempData = df[(rN==i+1)&(aN==j+1)]
			tempT    = tempData["time"]

			if i == 0:
				shortest_tempT = len(tempT)
				
			if len(tempT) < shortest_tempT:
				shortest_tempT = len(tempT)
				
			
			tempT = tempT[0:shortest_tempT]
			tempX = tempData["x"]
			tempX = tempX[0:shortest_tempT]
			tempY = tempData["y"]
			tempY = tempY[0:shortest_tempT]

			rawData = rawData[:,:,:,0:shortest_tempT] # chopping data to the shortest
			rawData[i,j,:,:] = [tempT, tempX, tempY]


	agentVar = np.zeros((4,nAgents,len(tempT)))
	for j in range(nAgents):
		rawX = np.squeeze(rawData[:,j,1,:])
		rawY = np.squeeze(rawData[:,j,2,:])
		
		varX = np.var(rawX,0)
		varY = np.var(rawY,0)
		
		mean_variance = (varX + varY)/2
		max_variance  = np.amax([varX,varY],0)
		
		mean_deviation = np.sqrt(mean_variance)
		max_deviation  = np.sqrt(max_variance)                 
		
		agentVar[0,j,:] = varX
		agentVar[1,j,:] = varY
		agentVar[2,j,:] = mean_deviation
		agentVar[3,j,:] = max_deviation

	eps = np.finfo(np.double).eps

	Total_mean_deviation = np.mean(agentVar[2,:,:])
	Total_max_deviation  = np.max(agentVar[3,:,:])

	print("=========================================")
	print("Total_mean_deviation (in meters) = %.2E" %Total_mean_deviation)
	print("Total_max_deviation  (in meters) =  %.2E" %Total_max_deviation)
	print("=========================================")


	print('Determinisim post processing DONE!')
	return Total_mean_deviation, Total_max_deviation
	


# Wraps angle to (-pi,pi] range
def wraptopi(x):
	if x > np.pi:
		x = x - (np.floor(x / (2 * np.pi)) + 1) * 2 * np.pi
	elif x < -np.pi:
		x = x + (np.floor(x / (-2 * np.pi)) + 1) * 2 * np.pi
	return x

def calculateDistance(x1,y1,x2,y2):
	dist = math.sqrt((x2 - x1)**2 + (y2 - y1)**2)
	return dist

def Send_Control_Command(agentObject, throttle, steer, brake, hand_brake=False, reverse=False):

	"""
	Send control command to vehicle.

	Args:
		agent     : The agent vehicle object details
		throttle  : Throttle command for vehicle [0, 1]
		steer     : Steer command for vehicle [-1, 1]
		brake     : Brake command for vehicle [0, 1]
		hand_brake: Hand brake [True or False]
		reverse   : Reverse gear [True or False]
	"""
	control = carla.VehicleControl()

	# Clamp all values within their limits
	steer              = np.fmax(np.fmin(steer, 1.0), -1.0)
	throttle           = np.fmax(np.fmin(throttle, 1.0), 0)
	brake              = np.fmax(np.fmin(brake, 1.0), 0)

	control.steer      = steer
	control.throttle   = throttle
	control.brake      = brake
	control.hand_brake = hand_brake
	control.reverse    = reverse

	agentObject.apply_control(control)

def Run_Controller(agentObject, current_x, current_y, current_yaw, current_speed, waypoints_array, desired_speed, current_timestamp, frame):

	controller        = ROBOPILOT_agentsController.Controller2D(waypoints_array)

	controller.update_waypoints(waypoints_array)
	# Update values for usage in controller
	controller.update_values(current_x, current_y, current_yaw,
							current_speed, desired_speed,
							current_timestamp, frame)
	controller.update_controls()
	set_throttle, set_steer, set_brake = controller.get_commands()

	# set_throttle = 1
	# set_steer    = 1
	# set_brake    = 0
	return set_throttle, set_steer, set_brake


def AgentTypeToNo(agentType):

	if agentType in AV_list:
		agentTypeNo = 0

	elif agentType in Cars_list:
		agentTypeNo = 1

	elif agentType in Ped_list:
		agentTypeNo = 2

	elif agentType in HEV_list:
		agentTypeNo = 3

	elif agentType in Bicycle_list:
		agentTypeNo = 4

	elif agentType in Motorcyle_list:
		agentTypeNo = 5

	else:
		agentType   = 999 

	return agentTypeNo

def AgentColourToRGB(agentColour):

	if agentColour == "red":
		RGB_colour = "255,0,0"

	elif agentColour == "yellow":
		RGB_colour = "255,255,0"

	elif agentColour == "blue":
		RGB_colour = "0,0,255"

	elif agentColour == "white":
		RGB_colour = "255,255,255"

	elif agentColour == "black":
		RGB_colour = "0,0,0"

	else:
		RGB_colour = "255,0,0" # Default to red

	return RGB_colour


def CheckIfWalker(agentType):
	if agentType in Ped_list:
		isWalker   = True
		isVehicle  = False
	else:
		isWalker   = False
		isVehicle  = True

	return isWalker, isVehicle

def Get_Test_Name(TestID,crash):
	if TestID == 1 and crash == True:
		INPUT_FILENAME = "Determinisim_TEST_CarsCollision.txt"
	elif TestID == 1 and crash == False:
		INPUT_FILENAME = "Determinisim_TEST_Cars.txt"
	elif TestID == 2 and crash == True:
		INPUT_FILENAME = "Determinisim_TEST_CarsPeopleCollision.txt"
	elif TestID == 2 and crash == False:
		INPUT_FILENAME = "Determinisim_TEST_CarsPeople.txt"
	elif TestID == 3 and crash == True:
		INPUT_FILENAME = "Determinisim_TEST_PeopleCollsion.txt"
	elif TestID == 3 and crash == False:
		INPUT_FILENAME = "Determinisim_TEST_People.txt"
	return INPUT_FILENAME





def main():
	argparser = argparse.ArgumentParser(
		description=__doc__)
	argparser.add_argument(
		'--host',
		metavar='H',
		default='127.0.0.1',
		help='IP of the host server (default: 127.0.0.1)')
	argparser.add_argument(
		'-p', '--port',
		metavar='P',
		default=2000,
		type=int,
		help='TCP port to listen to (default: 2000)')
	argparser.add_argument(
		'-n', '--n',
		metavar='n',
		default=1,
		type=int,
		help='Number of test repeats')
	argparser.add_argument(
		'--filterv',
		metavar='PATTERN',
		default='vehicle.*',
		help='vehicles filter (default: "vehicle.*")')
	argparser.add_argument(
		'--filterw',
		metavar='PATTERN',
		default='walker.pedestrian.*',
		help='pedestrians filter (default: "walker.pedestrian.*")')
	argparser.add_argument(
		'-TestID', '--TestID',
		metavar='TestID',
		default=1,
		type=int,
		help='Test ID (default: 1)')
	argparser.add_argument(
		'-crash', '--crash',
		dest='crash',
		action='store_true',
		help='Test with crash')
	argparser.add_argument(
		'-nocrash', '--nocrash',
		dest='crash',
		action='store_false',
		help='Test with no crash')
	argparser.add_argument(
		'-OF', '--output_file_name',
		dest='OF',
		default='default_name.txt',
		help='Output_file_name')
	argparser.add_argument(
		'-no_rendering', '--no_rendering',
		dest='no_rendering',
		action='store_true',
		help='Run Test with out rendering, Note: array outputs from cameras and GPU based sensors will be empty in this mode')
	args = argparser.parse_args()

	logging.basicConfig(format='%(levelname)s: %(message)s', level=logging.INFO)

	vehicles_list = []
	walkers_list = []
	all_walkers_id = []

	client = carla.Client(args.host, args.port)
	client.set_timeout(2.0)

	try:

		#=============================================
		#===Connecting to Simulator
		#=============================================
		print("PROGRESS: Connecting to Simulator, please wait for me! Will notify you when I am done :)")
		world = client.get_world()

		settings = world.get_settings()

		settings.fixed_delta_seconds = 0.05
		settings.synchronous_mode = True

		if args.no_rendering:
			settings.no_rendering_mode = True
			print("NOTE: array outputs from cameras and GPU based sensors will be empty because you are in no rendering mode")
		else:
			settings.no_rendering_mode = False
		world.apply_settings(settings)


		blueprints = world.get_blueprint_library().filter(args.filterv)
		blueprintsWalkers = world.get_blueprint_library().filter(args.filterw)


		# @todo cannot import these directly.
		SpawnActor = carla.command.SpawnActor
		SetAutopilot = carla.command.SetAutopilot
		FutureActor = carla.command.FutureActor

		print("PROGRESS: Connected to Simulator! :)")

		#=============================================
		#===Load data
		#=============================================
		INPUT_FILENAME			= Get_Test_Name(args.TestID,args.crash)
		df        				= Read_Test_File(INPUT_FOLDER,INPUT_FILENAME)
		n         				= df["AgentNo"].max()  
		NUMBER_OF_TEST_REPEATS  = args.n 
		RESULTS_OUTPUT_FILENAME  = args.OF
		print(RESULTS_OUTPUT_FILENAME)

		#=============================================
		#===Interpolating waypoints 
		#=============================================
		print("PROGRESS: I have started interpolating the agents' waypoints, please wait for me to finish! I will notify you when I am done :)")

		df_interp      = pd.DataFrame({"AgentNo":[], "AgentType":[], "X":[], "Y":[], "V":[]})                                 # Init interpolated dataframe

		df_interp_hash = []                                                                                                   # Hash table for indexing

		plotting_data  = pd.DataFrame({"AgentNo":[], "AgentType":[], "start_x":[], "start_y":[], "end_x":[], "end_y":[]})     # Init plotting data dataframe 



		for i in range(1, n+1):                                                                                               # Loop to extract waypoints for agent number i

			current_vehicle_data = df.loc[(df["AgentNo"] == i)]                                                             # Extract the current vehicle data in the loop


			plotting_data_row    = pd.DataFrame({"AgentNo":[current_vehicle_data["AgentNo"].iloc[0]],
												"AgentType":[current_vehicle_data["AgentType"].iloc[0]],
												"start_x":[current_vehicle_data["X"].iloc[0]],
												"start_y":[current_vehicle_data["Y"].iloc[0]],
												"end_x":[current_vehicle_data["X"].iloc[-1]],
												"end_y":[current_vehicle_data["Y"].iloc[-1]]})

			plotting_data        = plotting_data.append(plotting_data_row, ignore_index = True)


			wp_original          = current_vehicle_data.loc[:,['X','Y','V']].values                   # Extract the original X, Y and V inform of an array for current vehicle


			#=== Interpolate the arrray ===
			wp_distance = []                                                                          # Array for list of distances between waypoints

			for j in range (1, current_vehicle_data.shape[0]):
				wp_distance.append(
					np.sqrt((current_vehicle_data["X"].values[j] - current_vehicle_data["X"].values[j-1])**2 +
							(current_vehicle_data["Y"].values[j] - current_vehicle_data["Y"].values[j-1])**2))

			wp_distance.append(0)                                                                     # Last distance is 0 because it is the distance 
																									  # from the last waypoint to the last waypoint.

			interp_counter = 0

			volatile_df    = pd.DataFrame({"AgentNo":[], "AgentType":[], "X":[], "Y":[], "V":[]}) # Volatile df to store current vehicle data

			interp_hash    = []

			# Loop for actual interpolation
			for k in range(0, current_vehicle_data.shape[0]):
				volatile_df_row   = pd.DataFrame({"AgentNo":[current_vehicle_data["AgentNo"].values[0]],
												"AgentType":[current_vehicle_data["AgentType"].values[0]],
												"X":[current_vehicle_data["X"].values[k]],
												"Y":[current_vehicle_data["Y"].values[k]],
												"V":[current_vehicle_data["V"].values[k]]})

				volatile_df       = volatile_df.append(volatile_df_row, ignore_index = True)

				interp_hash.append(interp_counter)
				interp_counter+=1 

				# Interpolate to the next waypoint. First compute the number of
				# points to interpolate based on the desired resolution and 
				# incremmentally add interpolated points until the next waypoint 
				# is about to be reached.
				num_pts_to_interp = int(np.floor(wp_distance[k] / float(INTERP_DISTANCE_RES)))
				if k < current_vehicle_data.shape[0] - 1:
					wp_vector         = wp_original[k+1] - wp_original[k]
					wp_uvector        = wp_vector / np.linalg.norm(wp_vector)

					for l in range(0, num_pts_to_interp):
						next_wp_vector = INTERP_DISTANCE_RES * float(l+1) * wp_uvector
						volatile_df_row    = pd.DataFrame({"AgentNo":[current_vehicle_data["AgentNo"].values[0]],
														"AgentType":[current_vehicle_data["AgentType"].values[0]],
														"X":[current_vehicle_data["X"].values[k] + next_wp_vector[0]],
														"Y":[current_vehicle_data["Y"].values[k] + next_wp_vector[1]],
														"V":[current_vehicle_data["V"].values[k] + next_wp_vector[2]]})
						volatile_df        = volatile_df.append(volatile_df_row, ignore_index = True)
						interp_counter+=1

			df_interp = df_interp.append(volatile_df)
		print("PROGRESS: I am done interpolating the agents' waypoints")

		#=============================================
		#===Set Weather Conditions 
		#=============================================
		weather = carla.WeatherParameters(
			cloudyness=80.0,
			precipitation=30.0,
			sun_altitude_angle=70.0)
		world.set_weather(weather)


		#=============================================
		#===Test-Repeat Loop 
		#=============================================
		print("PROGRESS: Started Running Tests")

		for current_test_repeat_number in range(1, NUMBER_OF_TEST_REPEATS+1):

			print("PROGRESS: Running Repeat No %d/%d" % (current_test_repeat_number, NUMBER_OF_TEST_REPEATS))

			#=============================================
			#===Spawn Agents 
			#=============================================
			Types_list       = []  # Vehicle = 1, Walker = 2
			Types_list_index = []
			Track_V_Number   = 0 
			Track_W_Number   = 0

			vehicles_list    = []
			walkers_list     = []
			all_walkers_id           = []

			batch_V          = []
			batch_W          = []
			batch_W_C        = []


			for i in range(n):
				current_agent_data   = df.loc[(df["AgentNo"] == i + 1)]                                                         # Extract the current agent data in the loop.                                    
				current_agentType    = current_agent_data["AgentType"].values[0]                                                # Extract the current agent type.
				isWalker, isVehicle  = CheckIfWalker(current_agentType)                                                         # Check if agent is vehicle or walker.

				# For a vehicle
				if isVehicle:
					current_agentColour = AgentColourToRGB(current_agent_data["Colour"].values[0])
					print(current_agentColour)
					# print("Is a vehicle")
					Track_V_Number = Track_V_Number + 1 
					Types_list_index.append(Track_V_Number)
					Types_list.append(1)
					blueprint = random.choice(world.get_blueprint_library().filter(current_agentType))
					blueprint.set_attribute('color', current_agentColour)


					# if blueprint.has_attribute('color'):                                                                        # This we might not need...?
					# 	color = random.choice(blueprint.get_attribute('color').recommended_values)
					# 	blueprint.set_attribute('color', color)
					# blueprint.set_attribute('role_name', 'autopilot')


					#Calculate spawn orientation from the first two trajectory points
					spawn_orientation = np.rad2deg(np.pi + np.arctan2(current_agent_data["Y"].values[0] - current_agent_data["Y"].values[1], current_agent_data["X"].values[0] - current_agent_data["X"].values[1]))
					transform = carla.Transform(carla.Location(x=float(current_agent_data["X"].values[0]), y=float(current_agent_data["Y"].values[0]), z=float(2)), carla.Rotation(yaw=float(spawn_orientation)))
					# transform = carla.Transform(carla.Location(x=current_agent_data["X"].values[0], y=current_agent_data["Y"].values[0], z=0.5), carla.Rotation(yaw=spawn_orientation))
					batch_V.append(SpawnActor(blueprint, transform))

				# For a walker
				elif isWalker:
					# print("Is a walker")
					Track_W_Number = Track_W_Number + 1 
					Types_list_index.append(Track_W_Number)
					Types_list.append(2)
					# Spawning Walker Object
					walker_bp         = random.choice(world.get_blueprint_library().filter(current_agentType))              

					spawn_orientation = np.rad2deg(np.pi + np.arctan2(current_agent_data["Y"].values[0] - current_agent_data["Y"].values[1], current_agent_data["X"].values[0] - current_agent_data["X"].values[1]))
					transform = carla.Transform(carla.Location(x=float(current_agent_data["X"].values[0]), y=float(current_agent_data["Y"].values[0]), z=float(2)), carla.Rotation(yaw=float(spawn_orientation)))

					# Set as not invincible
					if walker_bp.has_attribute('is_invincible'):
						walker_bp.set_attribute('is_invincible', 'false')  

					batch_W.append(SpawnActor(walker_bp, transform))

				else:
					print("ERROR: Agent is neither a vehicle nor a walker" )

			# Sending sapwning command for Vehicles
			for response in client.apply_batch_sync(batch_V):
				if response.error:
					logging.error(response.error)
				else:
					vehicles_list.append(response.actor_id)

			# Sending sapwning command for Walkers Objects
			results = client.apply_batch_sync(batch_W, True)
			for i in range(len(results)):
				if results[i].error:
					logging.error(results[i].error)
				else:
					walkers_list.append({"id": results[i].actor_id})


			# Spawning Walker Controller
			walker_controller_bp = world.get_blueprint_library().find('controller.ai.walker')
			for i in range(len(walkers_list)):
				batch_W_C.append(SpawnActor(walker_controller_bp, carla.Transform(), walkers_list[i]["id"]))

			# Sending sapwning command for Walkers controllers
			results = client.apply_batch_sync(batch_W_C, True)
			for i in range(len(results)):
				if results[i].error:
					logging.error(results[i].error)
				else:
					walkers_list[i]["con"] = results[i].actor_id

			# Put together the walkers and controllers id to get the objects from their id
			for i in range(len(walkers_list)):
				all_walkers_id.append(walkers_list[i]["con"])
				all_walkers_id.append(walkers_list[i]["id"])
			all_actors = world.get_actors(all_walkers_id)

			# wait for a tick to ensure client receives the last transform of the walkers we have just created
			world.tick()

			print('spawned %d vehicles and %d walkers, press Ctrl+C to exit.' % (len(vehicles_list), len(walkers_list)))


			#=============================================
			#===Live plotting setup
			#=============================================
			if PLOTTING_FLAG == True:
				lp_traj = lv.LivePlotter(tk_title="Trajectory Trace")

				trajectory_fig = lp_traj.plot_new_dynamic_2d_figure(
					title='Vehicle Trajectory',
					figsize=(FIGSIZE_X_INCHES, FIGSIZE_Y_INCHES),
					edgecolor="black",
					rect=[PLOT_LEFT, PLOT_BOT, PLOT_WIDTH, PLOT_HEIGHT])

				trajectory_fig.set_invert_x_axis() # Because UE4 uses left-handed coordinate system the X axis in the graph is flipped

				trajectory_fig.set_axis_equal()    # X-Y spacing should be equal in size

				for i_plot in range(0, n):
					# Add start position markers
					start_x_plot = plotting_data["start_x"].values[i_plot]
					start_y_plot = plotting_data["start_y"].values[i_plot]
					trajectory_fig.add_graph("start_pos %d" %i_plot, window_size=1,
											x0=[start_x_plot], y0=[start_y_plot],
											marker=11, color=[1, 0.5, 0],
											markertext="Start_Pos%d"%i_plot, marker_text_offset=1)

					# Add end position markers
					end_x_plot = plotting_data["end_x"].values[i_plot]
					end_y_plot = plotting_data["end_y"].values[i_plot]
					trajectory_fig.add_graph("end_pos %d" %i_plot, window_size=1, 
											x0=[end_x_plot], y0=[end_y_plot],
											marker="D", color='r', 
											markertext="End_Pos%d"%i_plot, marker_text_offset=1)

					# Add vehicles markers
					trajectory_fig.add_graph("agent %d" %i_plot, window_size=1,
											marker="s", color='b', markertext="A%d"%i_plot,
											marker_text_offset=1)

					# Add target marker
					trajectory_fig.add_graph("target %d" %i_plot, window_size=1,
											marker="s", color='y', markertext="T%d"%i_plot,
											marker_text_offset=1)

			#=============================================
			#===Initialising params & arrays 
			#=============================================  
			if current_test_repeat_number == 1:
				repeat_number_history    = []
				agentNo_history          = []
				agentID_history          = []
				agentType_history        = []
				agentTypeNo_history      = []
				time_history             = []
				fps_history              = []
				x_history                = []
				y_history                = []
				z_history                = []
				yaw_history              = []


			frame                           = None
			old_timestamp                   = 0 
			simulation_start_trigger        = 0 
			start_walkers_controllers_flag  = 0


			# Get IDs of vehicles and walkers
			world_vehicles_list = world.get_actors().filter('vehicle.*')
			world_walkers_list  = world.get_actors().filter('walker.pedestrian.*')
			total_no_of_agents  = len(world_vehicles_list) + len(world_walkers_list)


			#=============================================
			#===Continious Running Loop
			#============================================= 
			desired_speed_test                           = zeros([n]) + 1.5
			wp_counter                                   = zeros([n])
			longitudinal_error_previous                  = zeros([n])
			t_previous                                   = zeros([n])
			array_of_current_distances_to_destinations   = zeros([n])
			array_of_current_agents_speeds               = zeros([n])



			while True:

				#================================================
				#===Tick
				#================================================
				ts, frame = Ticking(world,frame)


				#================================================
				#===Execute Initial Wait Time
				#================================================
				# Running initial wait time so that environment is setup.
				if simulation_start_trigger == 0:
					start_of_initial_wait_time = ts.elapsed_seconds

					# Keep ticking while initial wait before start.
					while True:
						ts, frame = Ticking(world,frame)
						if ts.elapsed_seconds - start_of_initial_wait_time >= WAIT_TIME_BEFORE_START:
							break

					start_of_simulation_timestamp = ts.elapsed_seconds
					simulation_start_trigger      = 1




				#================================================
				#===Loop Over Agents 
				#================================================
				for i in range(1, total_no_of_agents+1):

					#================================================
					#===Check If Agent Is Vehicle Or Walker
					#================================================
					if Types_list[i-1] == 1:     
						i_vehicle                   = Types_list_index[i-1]
						agent                       = world_vehicles_list.find(vehicles_list[i_vehicle-1])
						isVehicle                   = True
						isWalker                    = False

					elif Types_list[i-1] == 2:
						i_walker                    = Types_list_index[i-1]
						agent                       = world_walkers_list.find(walkers_list[i_walker-1]["id"])
						isVehicle                   = False
						isWalker                    = True


					#================================================
					#===Gather Agents' Data
					#================================================
					agent_transform                 = agent.get_transform()
					agent_location                  = agent_transform.location  #  Can also get location by using: agent.get_location()
					agent_rotation                  = agent_transform.rotation
					agent_velocity                  = agent.get_velocity()      # This is an object vector

					current_agentNo                 = i
					current_agentID                 = agent.id
					current_agentType               = agent.type_id
					current_agentType_No            = AgentTypeToNo(current_agentType)
					current_timestamp               = ts.elapsed_seconds - start_of_simulation_timestamp
					current_fps                     = 1 / ts.delta_seconds
					current_x                       = agent_location.x
					current_y                       = agent_location.y
					current_z                       = agent_location.z
					current_yaw                     = wraptopi(math.radians(agent_rotation.yaw))
					current_velocity                = np.array([agent_velocity.x, agent_velocity.y, agent_velocity.z])      # This is an array as opposed to agent_velocity, which is an object
					current_speed                   = np.sqrt(current_velocity.dot(current_velocity))

					current_agent_trajectory_data = df_interp.loc[(df_interp["AgentNo"] == i )]
					current_agent_trajectory_data = current_agent_trajectory_data.reset_index(drop = True)

					# Store history
					if current_timestamp - old_timestamp >= LOGGING_TIME_INCREMENT :

						repeat_number_history.append(current_test_repeat_number)
						agentNo_history.append(current_agentNo)
						agentID_history.append(current_agentID)
						agentType_history.append(current_agentType)
						agentTypeNo_history.append(current_agentType_No)
						time_history.append(current_timestamp)
						fps_history.append(current_fps)
						x_history.append(current_x)
						y_history.append(current_y)
						z_history.append(current_z)
						yaw_history.append(current_yaw)

						# TODO Add speed
						# TODO Add acceleration
						# TODO Add risk factor 

						if i == total_no_of_agents:
							old_timestamp = current_timestamp # updating old timestamp after loop over all agents


					#================================================
					#===Apply Agents Controller For Vehicles
					#================================================
					if isVehicle:
						current_wp_counter             = wp_counter[i-1]
						current_wp_counter             = int(current_wp_counter)
						end_of_wp_counter              = current_agent_trajectory_data["X"].size-1
						over_look_ahead_min            = current_wp_counter

						speed_increment   = 0.1 #TODO remove this increment and make it follow the velocity trajcetory we've got in the table or have both as an option
						Target_speed      = current_agent_trajectory_data["V"].values[current_wp_counter]   
						if (current_speed >= 0.7 * desired_speed_test[i-1] and desired_speed_test[i-1] <= Target_speed):
							desired_speed_test[i-1] = desired_speed_test[i-1] + speed_increment

						if (current_speed >= 0.7 * desired_speed_test[i-1] and desired_speed_test[i-1] > Target_speed):
							desired_speed_test[i-1] = desired_speed_test[i-1] - speed_increment

						v_desired                     = desired_speed_test[i-1]
						v                             = current_speed
						t                             = current_timestamp
						throttle_output               = 0
						brake_output                  = 0
						PID_output                    = 0


						Kp_longitudinal               = 0.25
						Ki_longitudinal               = 0.03
						Kd_longitudinal               = 0.1
						K_feedforward                 = 0.1


						longitudinal_error            = v_desired - v
						integral_longitudinal_error   = longitudinal_error + longitudinal_error_previous[i-1]
						derivative_longitudinal_error = longitudinal_error - longitudinal_error_previous[i-1]

						dt                            = t - t_previous[i-1]


						PID_output = Kp_longitudinal * longitudinal_error + Ki_longitudinal * integral_longitudinal_error + Kd_longitudinal * derivative_longitudinal_error / dt

						if PID_output == float('Inf'):
							PID_output = 0

						feedforward_control           = K_feedforward * v_desired

						combined_control              = feedforward_control + PID_output

						if combined_control >= 0:
							throttle_output = combined_control
						elif combined_control < 0:
							brake_output    = combined_control


						l_d_min_vehicle                = 2    # Setting a minimum lookahead distance
						l_d                            = 0
						L                              = 2    # Length of Vehicle
						Kpp                            = 0.5  # Lateral controller gain

						while True:

							if current_wp_counter < end_of_wp_counter:


								try:
									l_d = calculateDistance(current_agent_trajectory_data["X"].values[current_wp_counter], current_agent_trajectory_data["Y"].values[current_wp_counter], current_x, current_y) 
								except IndexError:
									print("Index doesn't exist!")
									break

								if l_d >= l_d_min_vehicle:
									over_look_ahead_min = current_wp_counter
									break
								wp_counter[i-1]    = wp_counter[i-1] + 1
								current_wp_counter = wp_counter[i-1]
								current_wp_counter = int(current_wp_counter)

							else:
								over_look_ahead_min = current_wp_counter
								break


						try:
							alpha_hat = np.arctan2(current_agent_trajectory_data["Y"].values[over_look_ahead_min] - current_y, current_agent_trajectory_data["X"].values[over_look_ahead_min] - current_x)
							alpha     = alpha_hat - current_yaw
							delta = np.arctan(2 * L * np.sin(alpha) / (Kpp * v))

						except:
							delta = 0



						steer_output = delta


						longitudinal_error_previous[i-1] = longitudinal_error # Store forward longitudinal error to be used in next step
						t_previous[i-1]                  = t
						distance_from_destination = np.sqrt((current_agent_trajectory_data["X"].values[-1] - current_x)**2 + (current_agent_trajectory_data["Y"].values[-1] - current_y)**2)

						# Update Stopping distance suite the vehicle with highest the velocity, the 0.2 used below was chosen emperically.
						# check_stopping_distance = 0.2*Target_speed
						# if check_stopping_distance >= STOPPING_DISTANCE:
						# 	STOPPING_DISTANCE = 0.2*Target_speed

						if distance_from_destination  <=  STOPPING_DISTANCE:
							steer_output              = 0
							throttle_output           = 0
							brake_output              = 1

						else:
							steer_output              = np.fmax(np.fmin(steer_output, 1.0), -1.0)
							throttle_output           = np.fmax(np.fmin(throttle_output, 1.0), 0)
							brake_output              = np.fmax(np.fmin(brake_output, 1.0), 0)


						cmd_throttle = throttle_output#set_throttle
						cmd_steer    = steer_output#0#set_steer
						cmd_brake    = brake_output#set_brake
						Send_Control_Command(agent, throttle=cmd_throttle, steer=cmd_steer, brake=cmd_brake, hand_brake=False, reverse=False)


					#================================================
					#===Apply Agents Controller For Walkers
					#================================================
					if isWalker:

						l_d_min_walker                 = 2    # Setting a minimum lookahead distance
						l_d                            = 0

						current_wp_counter             = wp_counter[i-1]
						current_wp_counter             = int(current_wp_counter)
						end_of_wp_counter              = current_agent_trajectory_data["X"].size-1
						over_look_ahead_min            = current_wp_counter

						while True:

							if current_wp_counter < end_of_wp_counter:
								try:
									l_d = calculateDistance(current_agent_trajectory_data["X"].values[current_wp_counter], current_agent_trajectory_data["Y"].values[current_wp_counter], current_x, current_y)
								except IndexError:
									print("Index doesn't exist!")
									break

								if l_d >= l_d_min_walker:
									over_look_ahead_min = current_wp_counter
									break
								wp_counter[i-1]    = wp_counter[i-1] + 1
								current_wp_counter = wp_counter[i-1]
								current_wp_counter = int(current_wp_counter)



							else:
								over_look_ahead_min = current_wp_counter
								break


						if current_x == 0 and current_y == 0 and current_speed == 0:
							distance_from_destination = 0 # Then agent (normally a pedestrian) is DEAD!
							print("Pedestrian is DEAD!")
						else: 
							distance_from_destination = np.sqrt((current_agent_trajectory_data["X"].values[-1] - current_x)**2 + (current_agent_trajectory_data["Y"].values[-1] - current_y)**2)

						W_controller_index        = 2 * i_walker - 2

						# start walker controllers
						if start_walkers_controllers_flag == 0:
							for j in range(0, len(all_actors), 2):
								all_actors[j].start()
							start_walkers_controllers_flag = 1

						# set walk to point
						all_actors[W_controller_index].go_to_location(carla.Location(x=float(current_agent_trajectory_data["X"].values[over_look_ahead_min]), y=float(current_agent_trajectory_data["Y"].values[over_look_ahead_min]), z=float(0.2)))
						# random max speed
						all_actors[W_controller_index].set_max_speed(current_agent_trajectory_data["V"].values[current_wp_counter])#1 + random.random())    # max speed between 1 and 2 (default is 1.4 m/s)
						#TODO integrate speed 





					#================================================
					#===Update Figures
					#================================================
					# Update live plotter with new feedback
					if PLOTTING_FLAG == True:
						i_plot = i-1
						trajectory_fig.roll("agent %d" %i_plot, current_x, current_y)
						trajectory_fig.roll("target %d" %i_plot, current_agent_trajectory_data["X"].values[current_wp_counter], current_agent_trajectory_data["Y"].values[current_wp_counter])
						lp_traj.refresh()


 
					array_of_current_distances_to_destinations[i-1]   = distance_from_destination
					array_of_current_agents_speeds[i-1]               = current_speed

				#================================================
				#===Destroy All Agents At The End Of Test Run
				#================================================
				if max(array_of_current_distances_to_destinations) <= STOPPING_DISTANCE and max(array_of_current_agents_speeds) <= STOPPING_SPEED and REPEAT_TESTS == True:
					print('\ndestroying %d vehicles' % len(vehicles_list))
					client.apply_batch([carla.command.DestroyActor(x) for x in vehicles_list])

					# stop walker controllers (list is [controler, actor, controller, actor ...])
					for i in range(0, len(all_walkers_id), 2):
						all_actors[i].stop()

					print('\ndestroying %d walkers' % len(walkers_list))
					client.apply_batch([carla.command.DestroyActor(x) for x in all_walkers_id])

					# Break the while loop at the end of the test run. 
					break



	finally:

		settings.synchronous_mode = False
		world.apply_settings(settings)


		Write_Log_File(RESULTS_OUTPUT_FILENAME,RESULTS_OUTPUT_FOLDER,repeat_number_history, agentNo_history, agentID_history, agentType_history, agentTypeNo_history, time_history, fps_history, x_history, y_history, z_history, yaw_history)

		if NUMBER_OF_TEST_REPEATS > 1:
			Total_mean_deviation, Total_max_deviation = Determinisim_PostProcess(repeat_number_history, agentNo_history, agentID_history, agentType_history, agentTypeNo_history, time_history, fps_history, x_history, y_history, z_history, yaw_history)
		else: 
			print("Number of repeats is less than one cannot calculate variance")


		print('\ndestroying %d vehicles' % len(vehicles_list))
		client.apply_batch([carla.command.DestroyActor(x) for x in vehicles_list])

		# stop walker controllers (list is [controler, actor, controller, actor ...])
		for i in range(0, len(all_walkers_id), 2):
			all_actors[i].stop()

		print('\ndestroying %d walkers' % len(walkers_list))
		client.apply_batch([carla.command.DestroyActor(x) for x in all_walkers_id])


if __name__ == '__main__':

	try:
		main()
	except KeyboardInterrupt:
		pass
	finally:
		print('\ndone.')
