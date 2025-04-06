import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flag/flag.dart';
import '../../data/countries.dart';
import '../country_selection_dialog.dart';

class ProfileEditDialog {
  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required String? nickname,
    required int? userAge,
    required String? userGender,
    required String? userCountryCode,
    String? shortPW,
  }) {
    final TextEditingController nicknameController =
        TextEditingController(text: nickname);
    final TextEditingController ageController =
        TextEditingController(text: userAge?.toString());
    final TextEditingController shortPasswordController =
        TextEditingController(text: shortPW);

    String? selectedGender = userGender;
    String? selectedCountryCode = userCountryCode;
    Country? selectedCountry;
    String? shortPasswordError;

    // 국가 코드에 해당하는 Country 객체 찾기
    if (userCountryCode != null) {
      selectedCountry = countries.firstWhere(
        (country) => country.code == userCountryCode,
        orElse: () => countries.first,
      );
    }

    return showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            // Handle country selection
            void selectCountry() async {
              final country = await CountrySelectionDialog.show(dialogContext);
              if (country != null) {
                setState(() {
                  selectedCountry = country;
                  selectedCountryCode = country.code;
                });
              }
            }

            // Short password validation
            void validateShortPassword() {
              if (shortPasswordController.text.length != 2 ||
                  !RegExp(r'^[0-9]+$').hasMatch(shortPasswordController.text)) {
                setState(() {
                  shortPasswordError = 'Must be a 2-digit number';
                });
              } else {
                setState(() {
                  shortPasswordError = null;
                });
              }
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: SingleChildScrollView(
                child: Container(
                  padding: EdgeInsets.all(24),
                  width: 350,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: nicknameController,
                        decoration: InputDecoration(
                          labelText: 'Nickname',
                          hintText: 'Enter your nickname',
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: ageController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Age',
                          hintText: 'Enter your age',
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: Icon(Icons.cake_outlined),
                        ),
                      ),
                      SizedBox(height: 16),
                      // Gender selection
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gender',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        selectedGender = 'Male';
                                      });
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 12, horizontal: 16),
                                      decoration: BoxDecoration(
                                        color: selectedGender == 'Male'
                                            ? Colors.blue.shade700
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: selectedGender == 'Male'
                                              ? Colors.blue.shade700
                                              : Colors.grey.shade300,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.male,
                                            size: 18,
                                            color: selectedGender == 'Male'
                                                ? Colors.white
                                                : Colors.blue.shade700,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Male',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: selectedGender == 'Male'
                                                  ? Colors.white
                                                  : Colors.grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        selectedGender = 'Female';
                                      });
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 12, horizontal: 16),
                                      decoration: BoxDecoration(
                                        color: selectedGender == 'Female'
                                            ? Colors.pink.shade700
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: selectedGender == 'Female'
                                              ? Colors.pink.shade700
                                              : Colors.grey.shade300,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.female,
                                            size: 18,
                                            color: selectedGender == 'Female'
                                                ? Colors.white
                                                : Colors.pink.shade700,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Female',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: selectedGender == 'Female'
                                                  ? Colors.white
                                                  : Colors.grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      // Country selection
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    selectedCountry == null
                                        ? 'Select Country'
                                        : 'Country: ${selectedCountry!.name}',
                                    style: TextStyle(
                                      color: selectedCountry == null
                                          ? Colors.grey[600]
                                          : Colors.black,
                                      fontWeight: selectedCountry == null
                                          ? FontWeight.normal
                                          : FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (selectedCountry != null)
                                  Flag.fromString(
                                    selectedCountry!.code,
                                    height: 24,
                                    width: 32,
                                    borderRadius: 4,
                                  ),
                              ],
                            ),
                            SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: selectCountry,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.purple,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side:
                                      BorderSide(color: Colors.purple.shade200),
                                ),
                              ),
                              child: Text('Select Country'),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      // Short Password (PIN)
                      TextField(
                        controller: shortPasswordController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => validateShortPassword(),
                        maxLength: 2,
                        decoration: InputDecoration(
                          labelText: 'Multi-Game PIN',
                          hintText: 'Enter 2-digit PIN',
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: Icon(Icons.pin_outlined),
                          errorText: shortPasswordError,
                          counterText: "",
                          helperText: "2-digit PIN for multiplayer games",
                          helperStyle: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey.shade700,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                side: BorderSide(color: Colors.grey.shade300),
                                padding: EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text('Cancel'),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                // Validate before submission
                                validateShortPassword();
                                if (shortPasswordError != null) {
                                  return;
                                }

                                final updatedData = {
                                  'nickname': nicknameController.text,
                                  'age': int.tryParse(ageController.text),
                                  'gender': selectedGender,
                                  'country': selectedCountryCode,
                                  'shortPW': shortPasswordController.text,
                                };
                                Navigator.of(dialogContext).pop(updatedData);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple.shade400,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text('Save'),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(dialogContext).pop({'signOut': true});
                        },
                        icon: Icon(Icons.logout, size: 18),
                        label: Text('Sign Out'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          side: BorderSide(color: Colors.red.shade200),
                          padding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
