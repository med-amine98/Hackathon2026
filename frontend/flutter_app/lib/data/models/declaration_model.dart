// lib/data/models/declaration_model.dart

import 'package:flutter/material.dart';

class DeclarationModel {
  final String id;
  final String title;
  final String description;
  final String status;
  final DateTime date;
  final String vehicleInfo;
  final String? imageUrl;
  final Map<String, dynamic>? details;

  DeclarationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.date,
    required this.vehicleInfo,
    this.imageUrl,
    this.details,
  });

  factory DeclarationModel.fromJson(Map<String, dynamic> json) {
    return DeclarationModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Déclaration',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'en_attente',
      date: json['date'] != null 
          ? DateTime.parse(json['date'].toString()) 
          : DateTime.now(),
      vehicleInfo: json['vehicle_info']?.toString() ?? 'Véhicule non spécifié',
      imageUrl: json['image_url']?.toString(),
      details: json['details'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'date': date.toIso8601String(),
      'vehicle_info': vehicleInfo,
      'image_url': imageUrl,
      'details': details,
    };
  }

  String get statusLabel {
    switch (status) {
      case 'en_attente':
        return 'En attente';
      case 'en_cours':
        return 'En cours de traitement';
      case 'traite':
        return 'Traité';
      case 'rejete':
        return 'Rejeté';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'en_attente':
        return Colors.orange;
      case 'en_cours':
        return Colors.blue;
      case 'traite':
        return Colors.green;
      case 'rejete':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case 'en_attente':
        return Icons.hourglass_empty;
      case 'en_cours':
        return Icons.autorenew;
      case 'traite':
        return Icons.check_circle;
      case 'rejete':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }
}