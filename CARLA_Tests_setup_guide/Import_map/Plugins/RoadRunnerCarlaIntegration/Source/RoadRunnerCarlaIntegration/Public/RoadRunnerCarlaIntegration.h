// This is free and unencumbered software released into the public domain.
//
// Anyone is free to copy, modify, publish, use, compile, sell, or
// distribute this software, either in source code form or as a compiled
// binary, for any purpose, commercial or non - commercial, and by any
// means.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
// OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.

#pragma once

#include "CoreMinimal.h"
#include "Modules/ModuleManager.h"
#include <UnrealEd.h>

////////////////////////////////////////////////////////////////////////////////
// Plugin to streamline the RoadRunner to CARLA process
//	- Creates new map from BaseMap
//	- Moves static meshes for segmentation
//	- Creates materials instanced from CARLA's to work with weather
//	- Generates routes from OpenDRIVE
class FRoadRunnerCarlaIntegrationModule : public IModuleInterface
{
public:
	// Constants
	static const FString BaseMapPath;
	static const FString MapDestRelPath;
	static const FString OpenDriveDestRelPath;

	// CARLA segmentation path list
	static TArray<FString> PathList;
	// Segmentation enum
	enum SegmentationType
	{
		eRoad,
		eMarking,
		eTerrain,
		eProp,
		eSidewalk,
		eSign,
		eFoliage,
		eFence,
		ePole,
		eVehicle,
		eWall
	};

	// Import delegates
	static void RRCarlaPreImport(UFactory* inFactory, UClass* inClass, UObject* inParent, const FName& name, const TCHAR* type);
	static void RRCarlaPostImport(UFactory* inFactory, UObject* inCreateObject);

	/** IModuleInterface implementation */
	virtual void StartupModule() override;
	virtual void ShutdownModule() override;
};
