// lib/presentation/screens/declaration/declaration_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_insurance_advisor/presentation/bloc/declaration/declaration_bloc.dart';
import 'package:ai_insurance_advisor/presentation/widgets/declaration_step.dart';

class DeclarationScreen extends StatefulWidget {
  const DeclarationScreen({super.key});

  @override
  State<DeclarationScreen> createState() => _DeclarationScreenState();
}

class _DeclarationScreenState extends State<DeclarationScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  final TextEditingController _marqueController = TextEditingController();
  final TextEditingController _modeleController = TextEditingController();
  final TextEditingController _anneeController = TextEditingController();
  final TextEditingController _immatriculationController = TextEditingController();
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _heureController = TextEditingController();
  final TextEditingController _lieuController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<DeclarationBloc>().add(const LoadDeclarationDataEvent());
  }

  @override
  void dispose() {
    _marqueController.dispose();
    _modeleController.dispose();
    _anneeController.dispose();
    _immatriculationController.dispose();
    _nomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _ageController.dispose();
    _dateController.dispose();
    _heureController.dispose();
    _lieuController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildProgressBar(),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentStep = index);
              },
              children: [
                _buildStep1(),
                _buildStep2(),
                _buildStep3(),
                _buildStep4(),
              ],
            ),
          ),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: List.generate(4, (index) {
          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: index <= _currentStep
                    ? Theme.of(context).primaryColor
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep1() {
    return DeclarationStep(
      title: 'Informations du véhicule',
      icon: Icons.directions_car_rounded,
      fields: [
        _buildTextField('Marque', _marqueController, Icons.branding_watermark, 'Toyota'),
        _buildTextField('Modèle', _modeleController, Icons.directions_car_rounded, 'Corolla'),
        _buildTextField('Année', _anneeController, Icons.calendar_today, '2020'),
        _buildTextField('Immatriculation', _immatriculationController, Icons.confirmation_number, '123 TUN 456'),
      ],
    );
  }

  Widget _buildStep2() {
    return DeclarationStep(
      title: 'Informations du conducteur',
      icon: Icons.person_rounded,
      fields: [
        _buildTextField('Nom complet', _nomController, Icons.person, 'John Doe'),
        _buildTextField('Email', _emailController, Icons.email, 'john@email.com'),
        _buildTextField('Téléphone', _telephoneController, Icons.phone, '12 345 678'),
        _buildTextField('Âge', _ageController, Icons.cake, '25'),
      ],
    );
  }

  Widget _buildStep3() {
    return DeclarationStep(
      title: 'Détails de l\'accident',
      icon: Icons.warning_amber_rounded,
      fields: [
        _buildTextField('Date', _dateController, Icons.calendar_today, '15/07/2026'),
        _buildTextField('Heure', _heureController, Icons.access_time, '14:30'),
        _buildTextField('Lieu', _lieuController, Icons.location_on, 'Autoroute A1'),
        _buildTextField('Description', _descriptionController, Icons.description, 'Accrochage avec un autre véhicule'),
      ],
    );
  }

  Widget _buildStep4() {
    return DeclarationStep(
      title: 'Confirmation',
      icon: Icons.check_circle_rounded,
      fields: const [],
      isConfirmation: true,
      onConfirm: _submitDeclaration,
    );
  }

  void _submitDeclaration() {
    context.read<DeclarationBloc>().add(
      SubmitDeclarationEvent(
        date: _dateController.text,
        time: _heureController.text,
        location: _lieuController.text,
        description: _descriptionController.text,
        vehicleName: '${_marqueController.text} ${_modeleController.text}',
        driverName: _nomController.text,
        images: [],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, String hint) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: const Text('Précédent'),
              ),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                if (_currentStep < 3) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                } else {
                  _submitDeclaration();
                }
              },
              child: Text(_currentStep == 3 ? 'Envoyer' : 'Suivant'),
            ),
          ),
        ],
      ),
    );
  }
}