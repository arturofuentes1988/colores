import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

// Clase para representar cada color con su nombre y valor
class ColorOption {
  final String name;
  final Color color;

  ColorOption(this.name, this.color);

  // Sobrescribimos el método == y hashCode para poder usar contains correctamente
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ColorOption &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          color == other.color;

  @override
  int get hashCode => name.hashCode ^ color.hashCode;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Juego de Colores',
      theme: ThemeData(
        // Fondo pastel único
        scaffoldBackgroundColor: Colors.lightBlue.shade50,
        // Uso de Google Fonts para una tipografía moderna
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ),
        useMaterial3: true,
      ),
      home: const StartPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class StartPage extends StatelessWidget {
  const StartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fondo único
      backgroundColor: Colors.lightBlue.shade50,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '¡Bienvenido al Juego de Colores!',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                'Identifica correctamente el color del texto. ¡Buena suerte!',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const GamePage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40.0, vertical: 15.0),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0)),
                  elevation: 5,
                ),
                child: Text(
                  'Iniciar Juego',
                  style: GoogleFonts.poppins(
                    fontSize: 20.0,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with TickerProviderStateMixin {
  // Lista de colores especificados
  final List<ColorOption> _allColors = [
    ColorOption('Rojo', Colors.red),
    ColorOption('Verde', Colors.green),
    ColorOption('Azul', Colors.blue),
    ColorOption('Amarillo', Colors.yellow),
    ColorOption('Morado', Colors.purple),
    ColorOption('Negro', Colors.black),
  ];

  int _currentLevel = 1;
  int _attemptsLeft = 10;
  late ColorOption _wordColorOption; // Color del texto
  late String _wordText; // Texto mostrado
  List<ColorOption> _options = [];
  final Random _random = Random();
  bool _isGameOver = false;
  int _score = 0;
  int _highScore = 0;

  // Variables para el temporizador
  Timer? _timer;
  int _totalTime = 0; // Tiempo total acumulado

  // Controladores de animación
  late AnimationController _correctController;
  late AnimationController _incorrectController;

  // Para manejar la animación del botón seleccionado
  int? _selectedOptionIndex;

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    _generateWordAndOptions();

    // Inicializar controladores de animación
    _correctController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
      lowerBound: 0.0,
      upperBound: 1.0,
    )..addListener(() {
        setState(() {});
      });

    _incorrectController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _incorrectController.reset();
        }
      });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _correctController.dispose();
    _incorrectController.dispose();
    super.dispose();
  }

  // Carga la puntuación más alta desde SharedPreferences
  Future<void> _loadHighScore() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _highScore = prefs.getInt('highScore') ?? 0;
    });
  }

  // Guarda la puntuación más alta en SharedPreferences
  Future<void> _saveHighScore() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (_score > _highScore) {
      await prefs.setInt('highScore', _score);
      setState(() {
        _highScore = _score;
      });
    }
  }

  // Inicia el temporizador
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _totalTime++;
      });
    });
  }

  // Genera una nueva palabra y opciones de respuesta
  void _generateWordAndOptions() {
    // Selecciona una palabra al azar
    ColorOption selectedWord =
        _allColors[_random.nextInt(_allColors.length)];

    // Selecciona un color diferente para el texto
    ColorOption selectedColor;
    do {
      selectedColor = _allColors[_random.nextInt(_allColors.length)];
    } while (selectedColor.color == selectedWord.color);

    _wordText = selectedWord.name;
    _wordColorOption = selectedColor;

    // Determina el número de opciones según el nivel
    int totalOptions = (_currentLevel <= 5) ? 2 : 3;

    // Selecciona opciones sin repetir y que sean diferentes al color del texto
    List<ColorOption> tempOptions = [];
    while (tempOptions.length < (totalOptions - 1)) {
      ColorOption option = _allColors[_random.nextInt(_allColors.length)];
      if (!tempOptions.contains(option) &&
          option.color != _wordColorOption.color) {
        tempOptions.add(option);
      }
    }

    // Añade la opción correcta
    tempOptions.add(_wordColorOption);

    // Mezcla las opciones para aleatorizar su posición
    tempOptions.shuffle(_random);
    _options = tempOptions;
  }

  // Maneja la selección de una opción
  void _handleOptionSelected(int index) async {
    if (_isGameOver) return;

    ColorOption selectedOption = _options[index];
    setState(() {
      _selectedOptionIndex = index;
    });

    if (selectedOption.color == _wordColorOption.color) {
      // Respuesta correcta
      await _animateCorrect();
      setState(() {
        _score += 10;
        if (_currentLevel == 1 && _timer == null) {
          _startTimer(); // Inicia el temporizador al responder correctamente en el primer nivel
        }
        if (_currentLevel < 10) {
          _currentLevel++;
          _generateWordAndOptions();
          _selectedOptionIndex = null;
        } else {
          // Nivel 10 alcanzado, fin del juego
          _isGameOver = true;
          _timer?.cancel();
          _saveHighScore();
        }
      });
    } else {
      // Respuesta incorrecta
      await _animateIncorrect();
      setState(() {
        _attemptsLeft--;
        _selectedOptionIndex = null;
        if (_attemptsLeft <= 0) {
          // Fin del juego si se acaban los intentos
          _isGameOver = true;
          _timer?.cancel();
          _saveHighScore();
        }
      });
    }
  }

  // Animación para respuesta correcta
  Future<void> _animateCorrect() async {
    await _correctController.forward();
    await _correctController.reverse();
  }

  // Animación para respuesta incorrecta
  Future<void> _animateIncorrect() async {
    await _incorrectController.forward();
    await _incorrectController.reverse();
  }

  // Reinicia el juego
  void _restartGame() {
    setState(() {
      _currentLevel = 1;
      _attemptsLeft = 10;
      _score = 0;
      _totalTime = 0;
      _isGameOver = false;
      _timer?.cancel();
      _generateWordAndOptions();
      _selectedOptionIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Nivel $_currentLevel',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: _isGameOver ? _buildGameOverScreen() : _buildGameScreen(),
    );
  }

  // Pantalla de Fin del Juego
  Widget _buildGameOverScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '¡Juego Terminado!',
              style: GoogleFonts.poppins(
                fontSize: 28.0,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              'Nivel alcanzado: $_currentLevel',
              style: GoogleFonts.poppins(
                fontSize: 20.0,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Puntuación: $_score',
              style: GoogleFonts.poppins(
                fontSize: 20.0,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Tiempo Total: $_totalTime s',
              style: GoogleFonts.poppins(
                fontSize: 20.0,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Puntuación Máxima: $_highScore',
              style: GoogleFonts.poppins(
                fontSize: 20.0,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _restartGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40.0, vertical: 15.0),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0)),
                elevation: 5,
              ),
              child: Text(
                'Reiniciar Juego',
                style: GoogleFonts.poppins(
                  fontSize: 18.0,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Pantalla del Juego Activo
  Widget _buildGameScreen() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Información de intentos y tiempo total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoCard('Intentos', '$_attemptsLeft'),
              _buildInfoCard('Tiempo', '$_totalTime s'),
            ],
          ),
          const SizedBox(height: 40),
          // Palabra con color (sin fondo)
          Expanded(
            child: Center(
              child: Text(
                _wordText,
                style: GoogleFonts.poppins(
                  fontSize: 60.0,
                  color: _wordColorOption.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          // Opciones de respuesta
          Column(
            children: _options.asMap().entries.map((entry) {
              int idx = entry.key;
              ColorOption option = entry.value;
              bool isSelected = _selectedOptionIndex == idx;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: GestureDetector(
                  onTap: () => _handleOptionSelected(idx),
                  child: AnimatedScale(
                    scale: isSelected
                        ? (_correctController.isAnimating
                            ? 1.1
                            : (_incorrectController.isAnimating
                                ? 0.9
                                : 1.0))
                        : 1.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (_correctController.isAnimating
                                ? Colors.greenAccent
                                : (_incorrectController.isAnimating
                                    ? Colors.redAccent
                                    : _getButtonBackgroundColor(option.color)))
                            : _getButtonBackgroundColor(option.color),
                        borderRadius: BorderRadius.circular(15.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 15.0),
                      child: Text(
                        option.name,
                        style: GoogleFonts.poppins(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                          color: _getTextColor(option.color),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          // Puntuación Actual y Puntuación Máxima
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.score, color: Colors.blueAccent),
              const SizedBox(width: 10),
              Text(
                'Puntuación: $_score',
                style: GoogleFonts.poppins(
                  fontSize: 18.0,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 20),
              const Icon(Icons.star, color: Colors.blueAccent),
              const SizedBox(width: 10),
              Text(
                'Puntuación Máxima: $_highScore',
                style: GoogleFonts.poppins(
                  fontSize: 18.0,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Construye tarjetas informativas
  Widget _buildInfoCard(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16.0,
            color: Colors.blueAccent,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  // Determina el color de fondo del botón para asegurar buen contraste
  Color _getButtonBackgroundColor(Color optionColor) {
    // Colores similares al texto para aumentar dificultad
    return optionColor;
  }

  // Determina el color del texto del botón para asegurar legibilidad
  Color _getTextColor(Color backgroundColor) {
    // Si el color es oscuro, usa blanco; de lo contrario, negro
    double luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  // Muestra un diálogo de información
  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Instrucciones del Juego',
            style: GoogleFonts.poppins(),
          ),
          content: Text(
            'Selecciona el color correcto del texto mostrado.\n'
            'Avanza a través de los niveles respondiendo correctamente.\n'
            'Tu puntuación y tiempo total serán registrados al finalizar el juego.',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              child: Text(
                'Cerrar',
                style: GoogleFonts.poppins(color: Colors.blueAccent),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
