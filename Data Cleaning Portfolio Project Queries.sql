/* 
Cleaning Data in SQL Queries
*/

SELECT * FROM `nashville housing data for data cleaning`;

-----------------------------------------------------------------------------------------------------------------------------
-- Standarize Date Format
SELECT SaleDateConverted, CAST(SaleDate AS Date)
FROM `nashville housing data for data cleaning`;

UPDATE `nashville housing data for data cleaning`
SET SaleDate = CAST(SaleDate AS Date);


-- If it doesn't update properly
ALTER TABLE `nashville housing data for data cleaning`
ADD SaleDateConverted Date;

UPDATE `nashville housing data for data cleaning`
SET SaleDate = STR_TO_DATE(SaleDate, '%M %e, %Y');

---------------------------------------------------------------------------------------------------------------------------
-- Populate Property Address Data
SELECT * FROM `nashville housing data for data cleaning`
-- WHERE  PropertyAddress IS NULL
ORDER BY ParcelID;

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
-- IS NULL(a.PropertyAddress, b.PropertyAddress)
FROM `nashville housing data for data cleaning` AS a
JOIN `nashville housing data for data cleaning` AS b
ON a.ParcelID = b.ParcelID
AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL;

UPDATE `nashville housing data for data cleaning` AS a
JOIN `nashville housing data for data cleaning` AS b
ON a.ParcelID = b.ParcelID
AND a.UniqueID <> b.UniqueID
SET a.PropertyAddress = COALESCE(a.PropertyAddress, b.PropertyAddress)
WHERE a.PropertyAddress IS NULL;

------------------------------------------------------------------------------------------------------------------------
-- Breaking out Address into Individual Columns(Address, City, State)
SELECT PropertyAddress From `nashville housing data for data cleaning`;

SELECT 
  SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress) - 1) AS Address,
  SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress) + 1) AS Address
FROM `nashville housing data for data cleaning`
LIMIT 0, 50000;

ALTER TABLE `nashville housing data for data cleaning`
ADD PropertySplitAddress NVARCHAR(255);

UPDATE `nashville housing data for data cleaning`
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress)-1);

ALTER TABLE `nashville housing data for data cleaning`
ADD PropertySplitCity NVARCHAR(255);

UPDATE `nashville housing data for data cleaning`
SET PropertySplitCity = SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress)+1, CHAR_LENGTH(PropertyAddress));

---------------------------------------------------------------------------------------------------------------------------
-- select * from `nashville housing data for data cleaning`
SELECT 
   SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 3), ',', -1),
   SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1),
   SUBSTRING_INDEX(OwnerAddress, ',', 1)
FROM `nashville housing data for data cleaning`;

ALTER TABLE `nashville housing data for data cleaning`
ADD OwnerSplitAddress NVARCHAR(255);

UPDATE `nashville housing data for data cleaning`
SET OwnerSplitAddress = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 3), ',', -1);

ALTER TABLE `nashville housing data for data cleaning`
ADD OwnerSplitCity NVARCHAR(255);

UPDATE `nashville housing data for data cleaning`
SET OwnerSplitCity = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1);

ALTER TABLE `nashville housing data for data cleaning`
ADD OwnerSplitState NVARCHAR(255);

UPDATE `nashville housing data for data cleaning`
SET OwnerSplitState = SUBSTRING_INDEX(OwnerAddress, ',', 1);

SELECT * FROM `nashville housing data for data cleaning`;

----------------------------------------------------------------------------------------------------------------------------
-- Change Y and N to Yes and No in "Sold as Vccant" field
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM `nashville housing data for data cleaning`
GROUP BY SoldAsVacant
ORDER BY 2;

SELECT SoldAsVacant, 
  CASE 
    WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
  END AS MappedValue
FROM `nashville housing data for data cleaning`;

UPDATE `nashville housing data for data cleaning`
SET SoldAsVacant = CASE 
	WHEN SoldAsVacant = 'Y' THEN 'YES'
    WHEN SoldAsVacant = 'N' THEN 'NO'
ELSE SoldAsVacant
END;

-------------------------------------------------------------------------------------------------------------------------
-- Remove Duplicates
DELETE d
FROM `nashville housing data for data cleaning` AS d
JOIN (
    SELECT ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference,
           MIN(UniqueID) AS min_unique_id
    FROM `nashville housing data for data cleaning`
    GROUP BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
    HAVING COUNT(*) > 1
) AS duplicates
ON d.ParcelID = duplicates.ParcelID
   AND d.PropertyAddress = duplicates.PropertyAddress
   AND d.SalePrice = duplicates.SalePrice
   AND d.SaleDate = duplicates.SaleDate
   AND d.LegalReference = duplicates.LegalReference
   AND d.UniqueID <> duplicates.min_unique_id;

WITH RowNumCTE AS (
SELECT *, ROW_NUMBER() OVER (
PARTITION BY 
	ParcelID,
	PropertyAddress, 
    SalePrice, 
    SaleDate,
    LegalReference
ORDER BY UniqueID
)
row_num
FROM `nashville housing data for data cleaning`
)
SELECT * FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress;

SELECT * FROM `nashville housing data for data cleaning`;

-------------------------------------------------------------------------------------------------------------------------
-- Delete Unused Columns
SELECT * FROM `nashville housing data for data cleaning`;

ALTER TABLE `nashville housing data for data cleaning`
DROP COLUMN OwnerAddress;

ALTER TABLE `nashville housing data for data cleaning`
DROP COLUMN TaxDistrict;

ALTER TABLE `nashville housing data for data cleaning`
DROP COLUMN PropertyAddress;

ALTER TABLE `nashville housing data for data cleaning`
DROP COLUMN SaleDate;

SELECT * FROM `nashville housing data for data cleaning`;
