import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:car/services/translation_service.dart';
import 'package:car/models/request_status.dart';

class CreateRequestPage extends StatefulWidget {
  final SupabaseClient? supabaseClient;
  const CreateRequestPage({super.key, this.supabaseClient});

  @override
  State<CreateRequestPage> createState() => _CreateRequestPageState();
}

class _CreateRequestPageState extends State<CreateRequestPage> {
  late final SupabaseClient _supabase;
  RangeValues _currentRangeValues = const RangeValues(25000000, 75000000);
  String selectedCondition = 'New';
  Color selectedColor = Colors.black;
  bool _isLoading = false;
  Map<String, dynamic>? _editingRequest;

  String selectedMake = 'brand';
  final _modelController = TextEditingController();
  bool _makeError = false;
  bool _modelError = false;
  String selectedYear = '2023 - 2026';
  String selectedMileage = '0 - 10,000';
  final _requirementsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _supabase = widget.supabaseClient ?? Supabase.instance.client;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && _editingRequest == null) {
      _editingRequest = args;
      
      final bool fromDetail = args['from_car_detail'] ?? false;
      
      if (fromDetail) {
        // Pre-fill from car info
        final double price = (args['final_price'] ?? 0).toDouble();
        _currentRangeValues = RangeValues(
          price > 5000000 ? price - 5000000 : price,
          price + 5000000,
        );
        selectedCondition = (args['car_condition'] ?? args['condition'] ?? 'Used').toString();
        
        String make = (args['make'] ?? args['name'] ?? 'brand').toString();
        // Handle variations in naming
        if (make.toLowerCase().contains('land rover')) make = 'Land Rover';
        if (make.toLowerCase().contains('mercedes')) make = 'Mercedes‑Benz';
        if (make.toLowerCase().contains('range rover')) make = 'Range Rover';
        if (make.toLowerCase().contains('rolls royce')) make = 'Rolls‑Royce';
        
        selectedMake = make;
        _modelController.text = (args['model'] ?? '').toString();
        
        final year = args['year']?.toString();
        if (year != null) {
          int y = int.tryParse(year) ?? 2023;
          if (y >= 2023) {
            selectedYear = '2023 - 2026';
          } else if (y >= 2020) {
            selectedYear = '2020 - 2023';
          } else if (y >= 2016) {
            selectedYear = '2016 - 2020';
          } else {
            selectedYear = '2010 - 2016';
          }
        }
        
        String mileage = (args['mileage'] ?? '0 - 10,000').toString();
        selectedMileage = mileage.replaceAll(' km', '').replaceAll(' KM', '');
      } else {
        // Standard edit mode
        _currentRangeValues = RangeValues(
          (args['budget_min'] ?? 25000000).toDouble(),
          (args['budget_max'] ?? 75000000).toDouble(),
        );
        selectedCondition = (args['car_condition'] ?? 'New').toString();
        selectedMake = (args['make'] ?? 'brand').toString();
        _modelController.text = (args['model'] ?? '').toString();
        _requirementsController.text = (args['special_requirements'] ?? '').toString();
        
        String mileage = (args['mileage'] ?? '0 - 10,000').toString();
        selectedMileage = mileage.replaceAll(' km', '').replaceAll(' KM', '');
        
        if (args['year_min'] != null && args['year_max'] != null) {
          selectedYear = '${args['year_min']} - ${args['year_max']}';
        }
      }

      final reqColorName = args['exterior_color']?.toString() ?? args['color']?.toString();
      if (reqColorName != null) {
        bool found = false;
        colorNames.forEach((color, names) {
          if (names.values.contains(reqColorName)) {
            selectedColor = color;
            found = true;
          }
        });
        // Handle case where it might be a hex string or other format if not found in our map
        if (!found && reqColorName.startsWith('#')) {
           try {
             selectedColor = Color(int.parse(reqColorName.replaceFirst('#', '0xFF')));
           } catch (_) {}
        }
      }
    }
  }

  final List<Color> exteriorShades = [
    Colors.black,
    Colors.white,
    const Color(0xFF8E8E93),
    const Color(0xFF1C1C1E),
    const Color(0xFF002A54),
    const Color(0xFF8B0000),
  ];

  final List<Color> additionalShades = [
    const Color(0xFF2C3E50), // Midnight Blue
    const Color(0xFF27AE60), // British Racing Green
    const Color(0xFFF1C40F), // Solar Yellow
    const Color(0xFFE67E22), // Sunset Orange
    const Color(0xFF9B59B6), // Royal Purple
    const Color(0xFF95A5A6), // Nardo Grey
    const Color(0xFFD35400), // Burnt Orange
    const Color(0xFFC0C0C0), // Platinum Silver
    const Color(0xFFB87333), // Copper
    const Color(0xFF008080), // Teal
  ];

  final Map<Color, Map<String, String>> colorNames = {
    Colors.black: {'English': 'Black', 'Français': 'Noir'},
    Colors.white: {'English': 'White', 'Français': 'Blanc'},
    const Color(0xFF8E8E93): {'English': 'Silver', 'Français': 'Argent'},
    const Color(0xFF1C1C1E): {'English': 'Dark Grey', 'Français': 'Gris Foncé'},
    const Color(0xFF002A54): {'English': 'Deep Blue', 'Français': 'Bleu Nuit'},
    const Color(0xFF8B0000): {'English': 'Ruby Red', 'Français': 'Rouge Rubis'},
    // Additional Colors
    const Color(0xFF2C3E50): {'English': 'Midnight Blue', 'Français': 'Bleu Minuit'},
    const Color(0xFF27AE60): {'English': 'Racing Green', 'Français': 'Vert Racing'},
    const Color(0xFFF1C40F): {'English': 'Solar Yellow', 'Français': 'Jaune Solaire'},
    const Color(0xFFE67E22): {'English': 'Sunset Orange', 'Français': 'Orange Sunset'},
    const Color(0xFF9B59B6): {'English': 'Royal Purple', 'Français': 'Violet Royal'},
    const Color(0xFF95A5A6): {'English': 'Nardo Grey', 'Français': 'Gris Nardo'},
    const Color(0xFFD35400): {'English': 'Burnt Orange', 'Français': 'Orange Brûlé'},
    const Color(0xFFC0C0C0): {'English': 'Platinum Silver', 'Français': 'Argent Platine'},
    const Color(0xFFB87333): {'English': 'Copper', 'Français': 'Cuivre'},
    const Color(0xFF008080): {'English': 'Teal', 'Français': 'Sarcelle'},
  };

  void _showColorPicker(TranslationService ts) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: Color(0xFF141414),
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ts.translate('exterior_shade'),
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                ),
                itemCount: additionalShades.length,
                itemBuilder: (context, index) {
                  final color = additionalShades[index];
                  final isSelected = selectedColor == color;
                  return GestureDetector(
                    onTap: () {
                      setState(() => selectedColor = color);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                        border: Border.all(
                          color: isSelected ? const Color(0xFFD4AF37) : Colors.white10,
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    final ts = TranslationService();

    final makeInvalid = selectedMake == 'brand';
    final modelInvalid = _modelController.text.trim().isEmpty;

    if (makeInvalid || modelInvalid) {
      setState(() {
        _makeError = makeInvalid;
        _modelError = modelInvalid;
      });
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        Navigator.pushNamed(context, '/login');
        return;
      }

      int? yearMin;
      int? yearMax;
      try {
        final years = selectedYear.split(' - ');
        if (years.length == 2) {
          yearMin = int.tryParse(years[0]);
          yearMax = int.tryParse(years[1]);
        }
      } catch (_) {}

      final data = {
        'user_id': user.id,
        'make': selectedMake,
        'model': _modelController.text.trim(),
        'car_condition': selectedCondition,
        'budget_min': _currentRangeValues.start.toInt(),
        'budget_max': _currentRangeValues.end.toInt(),
        'year_min': yearMin,
        'year_max': yearMax,
        'currency': ts.currentCurrency,
        'mileage': selectedCondition == 'New' ? '0' : selectedMileage,
        'exterior_color': colorNames[selectedColor]?[ts.currentLanguage] ?? ts.translate('custom'),
        'special_requirements': _requirementsController.text.trim(),
        'status': RequestStatus.initiated.dbValue,
      };

      Map<String, dynamic> response;
      if (_editingRequest != null) {
        response = await _supabase
            .schema('cartel')
            .from('requests')
            .update(data)
            .eq('id', _editingRequest!['id'])
            .select()
            .single();
      } else {
        response = await _supabase
            .schema('cartel')
            .from('requests')
            .insert({...data, 'payment_status': 'Pending'})
            .select()
            .single();
      }

      if (mounted) {
        Navigator.pushNamed(context, '/payment', arguments: response);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _modelController.dispose();
    _requirementsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFD4AF37);
    const backgroundColor = Color(0xFF000000);
    const borderColor = Color(0xFF222222);
    const mutedForeground = Color(0xFF888888);

    final ts = TranslationService();

    return ListenableBuilder(
      listenable: ts,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: backgroundColor,
          body: Stack(
            children: [
              Positioned(
                top: 0,
                right: 0,
                child: IgnorePointer(
                  child: Container(
                    width: 256,
                    height: 256,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor.withOpacity(0.1),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 80,
                left: 0,
                child: IgnorePointer(
                  child: Container(
                    width: 288,
                    height: 288,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor.withOpacity(0.05),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Column(
                  children: [
                    _buildHeader(context, borderColor, mutedForeground, ts),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildProgressIndicator(primaryColor, mutedForeground, ts),
                            const SizedBox(height: 40),
                            _buildVehicleIdentity(primaryColor, mutedForeground, ts),
                            const SizedBox(height: 40),
                            _buildCondition(primaryColor, mutedForeground, ts),
                            const SizedBox(height: 40),
                            _buildInvestmentRange(primaryColor, mutedForeground, ts),
                            const SizedBox(height: 40),
                            Row(
                              children: [
                                Expanded(child: _buildProductionYear(primaryColor, mutedForeground, ts)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildMileageRange(primaryColor, mutedForeground, ts)),
                              ],
                            ),
                            const SizedBox(height: 40),
                            _buildAesthetics(primaryColor, mutedForeground, ts),
                            const SizedBox(height: 40),
                            _buildRequirements(primaryColor, mutedForeground, ts),
                            const SizedBox(height: 120),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildBottomButton(context, primaryColor, ts),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, Color borderColor, Color mutedForeground, TranslationService ts) {
    return Container(
      padding: const EdgeInsets.only(top: 48, bottom: 24, left: 24, right: 24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        border: Border(bottom: BorderSide(color: borderColor.withOpacity(0.5))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A).withOpacity(0.5),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            ),
          ),
          Expanded(
            child: Text(
              ts.translate('create_request'),
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(
            width: 40,
            child: Icon(Icons.info_outline_rounded, color: Colors.white24, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(Color primaryColor, Color mutedForeground, TranslationService ts) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ts.translate('onboarding'),
                    style: GoogleFonts.dmSans(
                      color: mutedForeground,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                  Text(
                    ts.translate('details'),
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: primaryColor.withOpacity(0.2)),
              ),
              child: Text(
                '${ts.translate('step')} 1 ${ts.translate('of')} 2',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 4,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(100),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: 0.5,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor.withOpacity(0.6), primaryColor],
                ),
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.4),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleIdentity(Color primaryColor, Color mutedForeground, TranslationService ts) {
    final List<String> makes = [ts.translate('brand'), 'Audi', 'Bentley', 'BMW', 'BYD', 'Cadillac', 'Chevrolet', 'Chrysler', 'Citroën', 'Dodge', 'Ferrari', 'Fiat', 'Ford', 'Geely', 'GMC', 'Honda', 'Hyundai', 'Isuzu', 'Jaguar', 'Jeep', 'Kia', 'Lamborghini', 'Land Rover', 'Lexus', 'Mahindra', 'Mazda', 'Mercedes‑Benz', 'Mini', 'Mitsubishi', 'Nissan', 'Peugeot', 'Porsche', 'Range Rover', 'Renault', 'Rolls‑Royce', 'Subaru', 'Suzuki', 'Tata Motors', 'Tesla', 'Toyota', 'Volkswagen'];
    if (!makes.contains(selectedMake)) {
      makes.insert(0, selectedMake);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(ts.translate('vehicle_identity'), mutedForeground),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDropdownField(
                ts.translate('make'),
                selectedMake == 'brand' ? ts.translate('brand') : selectedMake,
                makes,
                onChanged: (val) => setState(() {
                  selectedMake = val!;
                  _makeError = false;
                }),
                hasError: _makeError,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                ts.translate('model'),
                ts.translate('e_g_urus'),
                controller: _modelController,
                hasError: _modelError,
                onChanged: (_) => setState(() => _modelError = false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInvestmentRange(Color primaryColor, Color mutedForeground, TranslationService ts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLabel(ts.translate('investment_range'), mutedForeground),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: primaryColor.withOpacity(0.1)),
              ),
              child: Text(
                ts.currentCurrency,
                style: GoogleFonts.dmSans(
                  color: primaryColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              RangeSlider(
                values: _currentRangeValues,
                min: 0,
                max: 100000000,
                activeColor: primaryColor,
                inactiveColor: Colors.white.withOpacity(0.1),
                onChanged: (RangeValues values) {
                  setState(() {
                    _currentRangeValues = values;
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ts.translate('minimum'),
                          style: GoogleFonts.dmSans(
                            color: mutedForeground,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          ts.formatPrice(_currentRangeValues.start),
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          ts.translate('maximum'),
                          style: GoogleFonts.dmSans(
                            color: mutedForeground,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          ts.formatPrice(_currentRangeValues.end),
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatCurrency(double value) {
    return value.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  Widget _buildProductionYear(Color primaryColor, Color mutedForeground, TranslationService ts) {
    final List<String> years = ['2023 - 2026', '2020 - 2023', '2016 - 2020', '2010 - 2016'];
    if (!years.contains(selectedYear)) {
      years.insert(0, selectedYear);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(ts.translate('production_year'), mutedForeground),
        const SizedBox(height: 16),
        _buildDropdownField(
          '',
          selectedYear,
          years,
          icon: Icons.calendar_today_rounded,
          onChanged: (val) => setState(() => selectedYear = val!),
        ),
      ],
    );
  }

  Widget _buildMileageRange(Color primaryColor, Color mutedForeground, TranslationService ts) {
    bool isNew = selectedCondition == 'New';
    final List<String> mileageOptions = ['0', '0 - 10,000', '10,000 - 30,000', '30,000 - 60,000', '60,000+'];
    String currentVal = isNew ? '0' : selectedMileage;
    if (!mileageOptions.contains(currentVal)) {
      mileageOptions.insert(0, currentVal);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(ts.translate('mileage_range'), mutedForeground),
        const SizedBox(height: 16),
        _buildDropdownField(
          '',
          currentVal,
          mileageOptions,
          icon: Icons.speed_rounded,
          enabled: !isNew,
          itemLabelBuilder: (val) => '$val ${ts.translate('kilometers')}',
          onChanged: (val) => setState(() => selectedMileage = val!),
        ),
      ],
    );
  }

  Widget _buildCondition(Color primaryColor, Color mutedForeground, TranslationService ts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(ts.translate('condition'), mutedForeground),
        const SizedBox(height: 16),
        Container(
          height: 52,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              _buildConditionButton(ts.translate('new'), 'New', primaryColor),
              _buildConditionButton(ts.translate('used'), 'Used', primaryColor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConditionButton(String label, String value, Color primaryColor) {
    bool isSelected = selectedCondition == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedCondition = value),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              color: isSelected ? Colors.black : const Color(0xFF888888),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAesthetics(Color primaryColor, Color mutedForeground, TranslationService ts) {
    String selectedColorName = colorNames[selectedColor]?[ts.currentLanguage] ?? 'Custom';
    bool isAdditionalColor = !exteriorShades.contains(selectedColor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(ts.translate('aesthetics'), mutedForeground),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    ts.translate('exterior_shade'),
                    style: GoogleFonts.dmSans(
                      color: mutedForeground,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    selectedColorName,
                    style: GoogleFonts.dmSans(
                      color: primaryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ...exteriorShades.map((color) {
                    bool isSelected = selectedColor == color;
                    return GestureDetector(
                      onTap: () => setState(() => selectedColor = color),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                          border: color == Colors.white ? Border.all(color: Colors.white24) : null,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.5),
                                    spreadRadius: 2,
                                    blurRadius: 10,
                                  ),
                                ]
                              : [],
                        ),
                        child: isSelected
                            ? Icon(Icons.check_rounded, color: color == Colors.white ? Colors.black : primaryColor, size: 16)
                            : null,
                      ),
                    );
                  }),
                  GestureDetector(
                    onTap: () => _showColorPicker(ts),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isAdditionalColor ? selectedColor : Colors.white.withOpacity(0.05),
                        border: Border.all(
                          color: isAdditionalColor ? primaryColor : Colors.white.withOpacity(0.1),
                          width: isAdditionalColor ? 2 : 1,
                        ),
                        boxShadow: isAdditionalColor
                            ? [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.3),
                                  spreadRadius: 2,
                                  blurRadius: 8,
                                ),
                              ]
                            : [],
                      ),
                      child: Icon(
                        isAdditionalColor ? Icons.check_rounded : Icons.palette_outlined,
                        color: isAdditionalColor 
                          ? (selectedColor.computeLuminance() > 0.5 ? Colors.black : Colors.white)
                          : const Color(0xFF888888),
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRequirements(Color primaryColor, Color mutedForeground, TranslationService ts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(ts.translate('special_requirements'), mutedForeground),
        const SizedBox(height: 16),
        Stack(
          children: [
            TextField(
              controller: _requirementsController,
              maxLines: 5,
              style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: ts.translate('describe_requirements'),
                hintStyle: GoogleFonts.dmSans(color: Colors.white24, fontSize: 14),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: primaryColor.withOpacity(0.5)),
                ),
                contentPadding: const EdgeInsets.all(20),
              ),
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: Text(
                ts.translate('optional'),
                style: GoogleFonts.dmSans(
                  color: Colors.white10,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLabel(String text, Color mutedForeground) {
    return Text(
      text,
      style: GoogleFonts.montserrat(
        color: mutedForeground.withOpacity(0.8),
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 2.5,
      ),
    );
  }

  Widget _buildTextField(String label, String placeholder, {int maxLines = 1, TextEditingController? controller, bool hasError = false, ValueChanged<String>? onChanged}) {
    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Colors.red, width: 1.5),
    );
    return Stack(
      children: [
        TextField(
          controller: controller,
          maxLines: maxLines,
          onChanged: onChanged,
          style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: GoogleFonts.dmSans(color: Colors.white24, fontSize: 14),
            filled: true,
            fillColor: hasError ? Colors.red.withOpacity(0.08) : Colors.white.withOpacity(0.05),
            border: hasError ? errorBorder : OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            enabledBorder: hasError ? errorBorder : OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: hasError ? errorBorder : OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.5)),
            ),
            contentPadding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          ),
        ),
        if (label.isNotEmpty)
          Positioned(
            left: 16,
            top: 8,
            child: Text(
              label,
              style: GoogleFonts.dmSans(
                color: const Color(0xFF888888).withOpacity(0.6),
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDropdownField(String label, String value, List<String> items,
      {IconData? icon, bool enabled = true, ValueChanged<String?>? onChanged, String Function(String)? itemLabelBuilder, bool hasError = false}) {
    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Colors.red, width: 1.5),
    );
    return Stack(
      children: [
        Opacity(
          opacity: enabled ? 1.0 : 0.4,
          child: AbsorbPointer(
            absorbing: !enabled,
            child: DropdownButtonFormField<String>(
              value: value,
              isExpanded: true,
              dropdownColor: const Color(0xFF111111),
              style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                filled: true,
                fillColor: hasError ? Colors.red.withOpacity(0.08) : Colors.white.withOpacity(0.05),
                border: hasError ? errorBorder : OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                enabledBorder: hasError ? errorBorder : OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                focusedBorder: hasError ? errorBorder : OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.5)),
                ),
                contentPadding: EdgeInsets.fromLTRB(16, label.isEmpty ? 16 : 24, 16, label.isEmpty ? 16 : 12),
              ),
              items: items.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(itemLabelBuilder != null ? itemLabelBuilder(value) : value),
                );
              }).toList(),
              onChanged: enabled ? onChanged : null,
              icon: Icon(icon ?? Icons.keyboard_arrow_down_rounded, color: const Color(0xFF888888)),
            ),
          ),
        ),
        if (label.isNotEmpty)
          Positioned(
            left: 16,
            top: 8,
            child: Text(
              label,
              style: GoogleFonts.dmSans(
                color: const Color(0xFF888888).withOpacity(0.6),
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomButton(BuildContext context, Color primaryColor, TranslationService ts) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.8), Colors.black],
          ),
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
            elevation: 10,
            shadowColor: primaryColor.withOpacity(0.25),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      ts.translate('submit_request'),
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
        ),
      ),
    );
  }
}
