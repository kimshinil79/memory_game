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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: 300,
                height: 450,
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.public,
                          size: 28,
                          color: Colors.blue.shade600,
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.flag,
                          size: 24,
                          color: Colors.green.shade600,
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: '...',
                        prefixIcon: Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(
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
                    SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredCountries.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: Flag.fromString(
                              filteredCountries[index].code,
                              height: 24,
                              width: 32,
                              borderRadius: 4,
                            ),
                            title: Text(filteredCountries[index].name),
                            onTap: () {
                              Navigator.of(dialogContext)
                                  .pop(filteredCountries[index]);
                            },
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop(null);
                        },
                        icon: Icon(
                          Icons.close,
                          color: Colors.red.shade700,
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
