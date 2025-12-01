import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(PokemonApp());
}

class PokemonApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pokédex',
      theme: ThemeData(
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: Color(0xFFF2EDF5),
        fontFamily: 'Roboto',
      ),
      home: PokemonList(),
    );
  }
}
class PokemonList extends StatefulWidget {
  @override
  _PokemonListState createState() => _PokemonListState();
}

class _PokemonListState extends State<PokemonList> {
  List<Map<String, dynamic>> _pokemonList = [];
  bool _isLoading = false;
  TextEditingController _controller = TextEditingController();
  Map<String, dynamic>? _searchedPokemon;

  @override
  void initState() {
    super.initState();
    fetchPokemon();
  }

  Future<void> fetchPokemon() async {
    setState(() => _isLoading = true);
    try {
      final url = Uri.parse('https://pokeapi.co/api/v2/pokemon?limit=50');
      final response = await http.get(url);
      final data = json.decode(response.body);
      final results = data['results'] as List;

      List<Map<String, dynamic>> pokemonWithImages = [];
      for (var pokemon in results) {
        final detailsResp = await http.get(Uri.parse(pokemon['url']));
        final details = json.decode(detailsResp.body);
        pokemonWithImages.add({
          'name': pokemon['name'],
          'image': details['sprites']['front_default'],
        });
      }

      setState(() {
        _pokemonList = pokemonWithImages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print("Error fetching Pokémon: $e");
    }
  }

  Future<void> searchPokemon(String name) async {
    if (name.isEmpty) return;
    setState(() {
      _isLoading = true;
      _searchedPokemon = null;
    });
    try {
      final url = Uri.parse('https://pokeapi.co/api/v2/pokemon/$name');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          _searchedPokemon = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print("Error searching Pokémon: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          decoration: InputDecoration(hintText: "Buscar Pokémon"),
          onSubmitted: (value) => searchPokemon(value.trim().toLowerCase()),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(child: Text("Menú Pokémon")),
            ListTile(
              title: Text("Inicio"),
              onTap: () {
                Navigator.pop(context);
                setState(() => _searchedPokemon = null);
              },
            ),
            ListTile(
              title: Text("Actividad 2"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => Actividad2()));
              },
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_searchedPokemon != null)
                  Card(
                    margin: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Image.network(
                            _searchedPokemon!['sprites']['front_default']),
                        Text(_searchedPokemon!['name'].toUpperCase()),
                        Text("Altura: ${_searchedPokemon!['height']}"),
                        Text("Peso: ${_searchedPokemon!['weight']}"),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _pokemonList.length,
                    itemBuilder: (_, index) {
                      final p = _pokemonList[index];
                      return ListTile(
                        leading: Image.network(p['image'] ?? ""),
                        title: Text(
                            p['name'][0].toUpperCase() + p['name'].substring(1)),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}


// 🔹 Segunda pantalla: Actividad 2
class Actividad2 extends StatefulWidget {
  @override
  _Actividad2State createState() => _Actividad2State();
}

class _Actividad2State extends State<Actividad2> {
  List<String> _breeds = [];
  String? _selectedBreed;
  String? _imageUrl;
  bool _isLoading = false;
  double _opacity = 0;

  @override
  void initState() {
    super.initState();
    fetchBreeds();
  }

  Future<void> fetchBreeds() async {
    setState(() => _isLoading = true);
    try {
      final url = Uri.parse('https://dog.ceo/api/breeds/list/all');
      final response = await http.get(url);
      final data = json.decode(response.body);
      final breedsMap = data['message'] as Map<String, dynamic>;
      setState(() {
        _breeds = breedsMap.keys.toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print("Error fetching breeds: $e");
    }
  }

  Future<void> fetchRandomImage(String breed) async {
    setState(() {
      _isLoading = true;
      _imageUrl = null;
      _opacity = 0;
    });
    try {
      final url = Uri.parse('https://dog.ceo/api/breed/$breed/images/random');
      final resp = await http.get(url);
      final data = json.decode(resp.body);
      setState(() {
        _imageUrl = data['message'];
        _isLoading = false;
      });
      Future.delayed(Duration(milliseconds: 100), () {
        setState(() => _opacity = 1);
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print("Error fetching image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Actividad 2')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<String>(
              value: _selectedBreed,
              hint: Text("Selecciona una raza"),
              isExpanded: true,
              items: _breeds
                  .map((b) => DropdownMenuItem(
                        value: b,
                        child: Text(b[0].toUpperCase() + b.substring(1)),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedBreed = value);
                fetchRandomImage(value!);
              },
            ),
            SizedBox(height: 20),
            Expanded(
              child: Center(
                child: _isLoading
                    ? CircularProgressIndicator()
                    : _imageUrl != null
                        ? AnimatedOpacity(
                            opacity: _opacity,
                            duration: Duration(milliseconds: 500),
                            child: Image.network(
                              _imageUrl!,
                              height: 250,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Text("Selecciona una raza"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
