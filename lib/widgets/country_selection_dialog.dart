import 'package:flutter/material.dart';
import 'package:flag/flag.dart';
import '../data/countries.dart';

class CountrySelectionDialog {
  static Future<Country?> show(BuildContext context,
      {Country? selectedCountry}) {
    TextEditingController searchController = TextEditingController();
    List<Country> filteredCountries = List.from(countries);

    void filterCountries(String query) {
      if (query.trim().isEmpty) {
        filteredCountries = List.from(countries);
      } else {
        filteredCountries = countries
            .where((country) =>
                country.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    }

    return showDialog<Country?>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: const Color(0xFF0B0D13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
              ),
              child: Container(
                width: 300,
                height: 450,
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF2A2F3A),
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.public,
                          size: 28,
                          color: const Color(0xFF00E5FF),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.flag,
                          size: 24,
                          color: const Color(0xFFFF2D95),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search countries...',
                        hintStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF00E5FF)),
                        filled: true,
                        fillColor: const Color(0xFF1A1D26),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFFF2D95), width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          filterCountries(value);
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredCountries.length,
                        itemBuilder: (context, index) {
                          final country = filteredCountries[index];
                          final isSelected = selectedCountry?.code == country.code;
                          
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? const Color(0xFF1A1D26)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected 
                                    ? const Color(0xFFFF2D95)
                                    : Colors.transparent,
                                width: 1,
                              ),
                            ),
                            child: ListTile(
                              leading: Flag.fromString(
                                country.code,
                                height: 24,
                                width: 32,
                                borderRadius: 4,
                              ),
                              title: Text(
                                country.name,
                                style: TextStyle(
                                  color: isSelected 
                                      ? const Color(0xFFFF2D95)
                                      : Colors.white,
                                  fontWeight: isSelected 
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                              onTap: () {
                                Navigator.of(dialogContext).pop(country);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2F3A),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.red.shade400, width: 1),
                      ),
                      child: IconButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop(null);
                        },
                        icon: Icon(
                          Icons.close,
                          color: Colors.red.shade400,
                        ),
                        iconSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
