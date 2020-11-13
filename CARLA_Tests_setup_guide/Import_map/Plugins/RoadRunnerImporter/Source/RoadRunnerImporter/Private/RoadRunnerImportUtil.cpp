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

#include "RoadRunnerImportUtil.h"
#include "RoadRunnerImporterLog.h"

#include <ObjectTools.h>
#include <PackageTools.h>
#include <Runtime/XmlParser/Public/XmlFile.h>

#include <AssetRegistryModule.h>

#include <Developer/AssetTools/Public/AssetToolsModule.h>
#include <Developer/AssetTools/Public/IAssetTools.h>
#include <PlatformFilemanager.h>

namespace
{
	FString GetTempFolderAbsolute()
	{
#if ENGINE_MINOR_VERSION > 17
		FString pluginsFolder = FPaths::ProjectPluginsDir();
#else
		FString pluginsFolder = FPaths::GamePluginsDir();
#endif
		FString filesystemTempPath = IFileManager::Get().ConvertToAbsolutePathForExternalAppForRead(*(pluginsFolder + "RoadRunnerImporter/Content/TEMP"));

		return filesystemTempPath;
	}
}

////////////////////////////////////////////////////////////////////////////////
// Helper function to parse the material info from the *.rrdata.xml file
TArray<FRoadRunnerImportUtil::MaterialInfo> FRoadRunnerImportUtil::ParseMaterialXml(FXmlNode * matList)
{
	TArray<MaterialInfo> retList;
	const auto& xmlMats = matList->GetChildrenNodes();

	for (const auto& mat : xmlMats)
	{
		const auto& matProperties = mat->GetChildrenNodes();

		// Fill out material info struct based off xml
		FRoadRunnerImportUtil::MaterialInfo matInfo;
		for (const auto& matProperty : matProperties)
		{
			const FString& tag = matProperty->GetTag();
			if (tag.Equals(TEXT("Name"), ESearchCase::CaseSensitive))
			{
				matInfo.Name = matProperty->GetContent();
			}
			else if (tag.Equals(TEXT("DiffuseMap"), ESearchCase::CaseSensitive))
			{
				matInfo.DiffuseMap = matProperty->GetContent();
			}
			else if (tag.Equals(TEXT("NormalMap"), ESearchCase::CaseSensitive))
			{
				matInfo.NormalMap = matProperty->GetContent();
			}
			else if (tag.Equals(TEXT("SpecularMap"), ESearchCase::CaseSensitive))
			{
				matInfo.SpecularMap = matProperty->GetContent();
			}
			else if (tag.Equals(TEXT("DiffuseColor"), ESearchCase::CaseSensitive))
			{
				matInfo.DiffuseColor = matProperty->GetContent();
			}
			else if (tag.Equals(TEXT("TransparentColor"), ESearchCase::CaseSensitive))
			{
				matInfo.TransparencyMap = matProperty->GetContent();
			}
			else if (tag.Equals(TEXT("TransparencyFactor"), ESearchCase::CaseSensitive))
			{
				matInfo.TransparencyFactor = matProperty->GetContent();
			}
			else if (tag.Equals(TEXT("SpecularColor"), ESearchCase::CaseSensitive))
			{
				matInfo.SpecularColor = matProperty->GetContent();
			}
			else if (tag.Equals(TEXT("SpecularFactor"), ESearchCase::CaseSensitive))
			{
				matInfo.SpecularFactor = matProperty->GetContent();
			}
			else if (tag.Equals(TEXT("Roughness"), ESearchCase::CaseSensitive))
			{
				matInfo.Roughness = matProperty->GetContent();
			}
			else if (tag.Equals(TEXT("Emission"), ESearchCase::CaseSensitive))
			{
				matInfo.Emission = matProperty->GetContent();
			}
			else if (tag.Equals(TEXT("TextureScaleU"), ESearchCase::CaseSensitive))
			{
				matInfo.TextureScaleU = matProperty->GetContent();
			}
			else if (tag.Equals(TEXT("TextureScaleV"), ESearchCase::CaseSensitive))
			{
				matInfo.TextureScaleV = matProperty->GetContent();
			}
			else if (tag.Equals(TEXT("TwoSided"), ESearchCase::CaseSensitive))
			{
				matInfo.TwoSided = matProperty->GetContent();
			}
			else if (tag.Equals(TEXT("DrawQueue"), ESearchCase::CaseSensitive))
			{
				matInfo.DrawQueue = matProperty->GetContent();
			}
			else if (tag.Equals(TEXT("ShadowCaster"), ESearchCase::CaseSensitive))
			{
				matInfo.ShadowCaster = matProperty->GetContent();
			}
			else if (tag.Equals(TEXT("IsDecal"), ESearchCase::CaseSensitive))
			{
				matInfo.IsDecal = matProperty->GetContent();
			}
			else if (tag.Equals(TEXT("AmbientColor")))
			{
				// Unused
			}
			else if (tag.Equals(TEXT("SegmentationType")))
			{
				matInfo.SegmentationType = matProperty->GetContent();
			}
			else
			{
				UE_LOG(RoadRunnerImporter, Warning, TEXT("Unrecognized element '%s' found in material property"), *tag);
			}
		}

		// Validation
		if (matInfo.Name.IsEmpty())
		{
			UE_LOG(RoadRunnerImporter, Warning, TEXT("Material is missing a name"));
			continue;
		}

		// Follow Unreal's naming scheme
		matInfo.Name = MakeName(matInfo.Name);
		matInfo.Name = ObjectTools::SanitizeObjectName(matInfo.Name);

		retList.Add(matInfo);
	}


	return retList;
}

////////////////////////////////////////////////////////////////////////////////
// Based off FbxMaterialImport.cpp:37 on version 4.20
// Significant modifications in logic are commented
// Creates a UTexture object from the file location and the package destination
UTexture* FRoadRunnerImportUtil::ImportTexture(FString absFilePath, FString packagePath, bool setupAsNormalMap)
{
	if (absFilePath.IsEmpty())
	{
		return nullptr;
	}

	// Create an unreal texture asset
	UTexture2D* unrealTexture = nullptr;
	FString extension = FPaths::GetExtension(absFilePath).ToLower();

	// Name the texture with file name
	FString textureName = FPaths::GetBaseFilename(absFilePath);
	textureName = ObjectTools::SanitizeObjectName(textureName);

	// Set where to place the texture in the project
	FString basePackageName = FPackageName::GetLongPackagePath(packagePath) / textureName;
	basePackageName = PackageTools::SanitizePackageName(basePackageName);

	UTexture2D* existingTexture = nullptr;
	UPackage* texturePackage = nullptr;

	// First check if the asset already exists.
	FString objectPath = basePackageName + TEXT(".") + textureName;
	existingTexture = LoadObject<UTexture2D>(NULL, *objectPath, nullptr, LOAD_Quiet | LOAD_NoWarn);

	// Modified: return existing texture if found instead of updating
	if (existingTexture)
	{
		return existingTexture;
	}

	const FString suffix(TEXT(""));
	// Create new texture asset
	FAssetToolsModule& assetToolsModule = FModuleManager::LoadModuleChecked<FAssetToolsModule>("AssetTools");
	FString finalPackageName;
	assetToolsModule.Get().CreateUniqueAssetName(basePackageName, suffix, finalPackageName, textureName);

	texturePackage = CreatePackage(NULL, *finalPackageName);

	// Modified: only use absolute file path since we don't deal with the uncertainty of fbx
	if (!IFileManager::Get().FileExists(*absFilePath))
	{
		UE_LOG(RoadRunnerImporter, Warning, TEXT("Unable to find Texture file %s"), *absFilePath);
		return nullptr;
	}

	bool fileReadSuccess = false;
	TArray<uint8> dataBinary;
	if (!absFilePath.IsEmpty())
	{
		fileReadSuccess = FFileHelper::LoadFileToArray(dataBinary, *absFilePath);
	}

	if (!fileReadSuccess || dataBinary.Num() <= 0)
	{
		UE_LOG(RoadRunnerImporter, Warning, TEXT("Unable to load Texture file %s"), *absFilePath);
		return nullptr;
	}

	UE_LOG(RoadRunnerImporter, Verbose, TEXT("Loading texture file %s"), *absFilePath);
	const uint8* textureData = dataBinary.GetData();
	// Modified: use scope guard for the factory (ver 4.15+) to avoid garbage collection
	UTextureFactory* textureFactory;
	FGCObjectScopeGuard(textureFactory = NewObject<UTextureFactory>());

	// Always re-import
	textureFactory->SuppressImportOverwriteDialog();
	const TCHAR* textureType = *extension;

	// Unless the normal map setting is used during import, 
	// the user has to manually hit "reimport" then "recompress now" button
	if (setupAsNormalMap)
	{
		if (!existingTexture)
		{
			textureFactory->LODGroup = TEXTUREGROUP_WorldNormalMap;
			textureFactory->CompressionSettings = TC_Normalmap;
			// Modified: removed import options
		}
		else
		{
			UE_LOG(RoadRunnerImporter, Warning, TEXT("Manual texture reimport and recompression may be needed for %s"), *textureName);
		}
	}

	unrealTexture = (UTexture2D*)textureFactory->FactoryCreateBinary(
		UTexture2D::StaticClass(), texturePackage, *textureName,
		RF_Standalone | RF_Public, NULL, textureType,
		textureData, textureData + dataBinary.Num(), GWarn);

	if (unrealTexture != NULL)
	{
		// Modified: Always sample as linear color
		if (setupAsNormalMap)
		{
			unrealTexture->SRGB = 0;
		}
		else
		{
			unrealTexture->SRGB = 1;
		}

		// Make sure the AssetImportData point on the texture file and not on the fbx files since the factory point on the fbx file
		unrealTexture->AssetImportData->Update(IFileManager::Get().ConvertToAbsolutePathForExternalAppForRead(*absFilePath));

		// Notify the asset registry
		FAssetRegistryModule::AssetCreated(unrealTexture);
		// Set the dirty flag so this package will get saved later
		texturePackage->SetDirtyFlag(true);
		texturePackage->PostEditChange();
	}
	else
	{
		UE_LOG(RoadRunnerImporter, Error, TEXT("Texture %s could not be created."), *textureName);
	}

	return unrealTexture;
}

////////////////////////////////////////////////////////////////////////////////
// Helper function to set texture parameter in a material instance
void FRoadRunnerImportUtil::SetTextureParameter(UMaterialInstanceConstant* material, const FName& paramName, const FString& baseFilePath, const FString& texturePath, const FString& packagePath, bool isNormal)
{
	if (texturePath.IsEmpty())
		return;

	FString texFileAbsPath = FPaths::ConvertRelativePathToFull(baseFilePath / texturePath);
	UTexture * texture = ImportTexture(texFileAbsPath, packagePath, isNormal);
	if (texture)
	{
#if ENGINE_MINOR_VERSION > 18
		material->SetTextureParameterValueEditorOnly(FMaterialParameterInfo(paramName, EMaterialParameterAssociation::GlobalParameter), texture);
#else
		material->SetTextureParameterValueEditorOnly(paramName, texture);
#endif
	}
}

////////////////////////////////////////////////////////////////////////////////
// Helper function to set color parameter in a material instance
void FRoadRunnerImportUtil::SetColorParameter(UMaterialInstanceConstant* material, const FName& paramName, const FString& colorString, float alphaVal)
{
	if (colorString.IsEmpty())
	{
		return;
	}

	TArray<FString> colorStrings;
	int numElements = colorString.ParseIntoArray(colorStrings, TEXT(","), true);
	if (numElements != 3)
	{
		UE_LOG(RoadRunnerImporter, Error, TEXT("Error: %s's %s value is invalid"), *(material->GetFName().ToString()), *(paramName.ToString()));
		return;
	}
	float r = FCString::Atof(*(colorStrings[0]));
	float g = FCString::Atof(*(colorStrings[1]));
	float b = FCString::Atof(*(colorStrings[2]));
#if ENGINE_MINOR_VERSION > 18
	material->SetVectorParameterValueEditorOnly(FMaterialParameterInfo(paramName, EMaterialParameterAssociation::GlobalParameter), FLinearColor(r, g, b, alphaVal));
#else
	material->SetVectorParameterValueEditorOnly(paramName, FLinearColor(r, g, b, alphaVal));
#endif

}

////////////////////////////////////////////////////////////////////////////////
// Helper function to set scalar parameter in a material instance
void FRoadRunnerImportUtil::SetScalarParameter(UMaterialInstanceConstant* material, const FName& paramName, const FString& valueString)
{
	if (valueString.IsEmpty())
		return;

	float value = FCString::Atof(*valueString);
#if ENGINE_MINOR_VERSION > 18
	material->SetScalarParameterValueEditorOnly(FMaterialParameterInfo(paramName, EMaterialParameterAssociation::GlobalParameter), value);
#else
	material->SetScalarParameterValueEditorOnly(paramName, value);
#endif

}

////////////////////////////////////////////////////////////////////////////////
// Copied from FbxMainImport.cpp:1210 on version 4.20
// Replaces invalid characters and cuts off colons
FString FRoadRunnerImportUtil::MakeName(const FString inName)
{
	const ANSICHAR* Name = TCHAR_TO_ANSI(*inName);
	const int SpecialChars[] = { '.', ',', '/', '`', '%' };

	const int len = FCStringAnsi::Strlen(Name);
	ANSICHAR* TmpName = new ANSICHAR[len + 1];

	FCStringAnsi::Strcpy(TmpName, len + 1, Name);

	for (int32 i = 0; i < ARRAY_COUNT(SpecialChars); i++)
	{
		ANSICHAR* CharPtr = TmpName;
		while ((CharPtr = FCStringAnsi::Strchr(CharPtr, SpecialChars[i])) != NULL)
		{
			CharPtr[0] = '_';
		}
	}

	// Remove namespaces
	ANSICHAR* NewName;
	NewName = FCStringAnsi::Strchr(TmpName, ':');

	// there may be multiple namespace, so find the last ':'
	while (NewName && FCStringAnsi::Strchr(NewName + 1, ':'))
	{
		NewName = FCStringAnsi::Strchr(NewName + 1, ':');
	}

	if (NewName)
	{
		return NewName + 1;
	}

	return UTF8_TO_TCHAR(TmpName);
}

////////////////////////////////////////////////////////////////////////////////
// Deletes the temporary folder created during re-import to back up the old
// version of assets.
void FRoadRunnerImportUtil::CleanUpTempFolder()
{
	if (!TempFolderExists())
	{
		return;
	}

	FString filesystemTempPath = GetTempFolderAbsolute();
	if (!FPlatformFileManager::Get().GetPlatformFile().DeleteDirectoryRecursively(*filesystemTempPath))
		UE_LOG(RoadRunnerImporter, Warning, TEXT("Failed to clean up TEMP directory. Manual cleanup may be needed."));

}

////////////////////////////////////////////////////////////////////////////////
// Check that the temporary folder exists in case previous import crashed
bool FRoadRunnerImportUtil::TempFolderExists()
{
	FString filesystemTempPath = GetTempFolderAbsolute();
	return FPlatformFileManager::Get().GetPlatformFile().DirectoryExists(*filesystemTempPath);
}

////////////////////////////////////////////////////////////////////////////////
// Fix up all object redirectors in the project
void FRoadRunnerImportUtil::FixUpRedirectors()
{
	FAssetRegistryModule& AssetRegistryModule = FModuleManager::Get().LoadModuleChecked<FAssetRegistryModule>(TEXT("AssetRegistry"));

	// Form a filter from the paths
	FARFilter filter;
	filter.bRecursivePaths = true;

	filter.PackagePaths.Emplace("/Game");
	filter.ClassNames.Emplace(TEXT("ObjectRedirector"));

	// Query for a list of assets in the selected paths
	TArray<FAssetData> assetList;
	AssetRegistryModule.Get().GetAssets(filter, assetList);

	if (assetList.Num() > 0)
	{
		TArray<UObjectRedirector*> redirectors;
		for (const auto& asset : assetList)
		{
			UE_LOG(RoadRunnerImporter, Log, TEXT("GOING TO FIX UP: %s"), *asset.PackageName.ToString());
			UPackage* pkg = PackageTools::LoadPackage(asset.PackageName.ToString());
			UObjectRedirector* redirector = LoadObject<UObjectRedirector>(pkg, *asset.AssetName.ToString());
			if(redirector)
				redirectors.Add(redirector);

		}

		// Load the asset tools module
		FAssetToolsModule& AssetToolsModule = FModuleManager::LoadModuleChecked<FAssetToolsModule>(TEXT("AssetTools"));
		AssetToolsModule.Get().FixupReferencers(redirectors);
	}
}
