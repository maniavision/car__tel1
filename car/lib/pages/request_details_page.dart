import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:car/services/translation_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RequestDetailsPage extends StatefulWidget {
  const RequestDetailsPage({super.key});

  @override
  State<RequestDetailsPage> createState() => _RequestDetailsPageState();
}

class _RequestDetailsPageState extends State<RequestDetailsPage> {
  final ts = TranslationService();
  List<Map<String, dynamic>> _matches = [];
  bool _isLoadingMatches = false;
  Map<String, dynamic>? _request;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _request = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (_request != null) {
        _fetchMatches();
      }
      _initialized = true;
    }
  }

  Future<void> _fetchMatches() async {
    final requestId = _request?['id'];
    if (requestId == null) return;

    setState(() => _isLoadingMatches = true);
    try {
      final response = await Supabase.instance.client
          .schema('cartel')
          .from('matches')
          .select()
          .eq('request_id', requestId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _matches = List<Map<String, dynamic>>.from(response);
          _isLoadingMatches = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching matches: $e');
      if (mounted) {
        setState(() => _isLoadingMatches = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFD4AF37);
    const backgroundColor = Color(0xFF0A0A0A);
    const cardColor = Color(0xFF141414);
    const borderColor = Color(0xFF2A2A2A);
    const mutedForeground = Color(0xFFA3A3A3);

    final status = _request?['status']?.toString().toLowerCase() ?? 'initialisée';
    final isFinished = status == 'terminee' || status == 'terminée';
    final isFound = _request?['resultat'] != null || status == 'trouvé' || status == 'trouvée' || status == 'found';

    bool showProcessingView = !isFinished && !isFound;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, primaryColor, borderColor, ts),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: showProcessingView
                    ? _buildProcessingLayout(context, primaryColor, cardColor, borderColor, mutedForeground, ts, _request)
                    : _buildFoundLayout(context, primaryColor, cardColor, borderColor, mutedForeground, ts, _request),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color primaryColor, Color borderColor, TranslationService ts) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A).withOpacity(0.8),
        border: Border(bottom: BorderSide(color: borderColor.withOpacity(0.4))),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF1F1F1F).withOpacity(0.5),
                shape: BoxShape.circle,
                border: Border.all(color: borderColor),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            ts.translate('details_demande'),
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingLayout(BuildContext context, Color primaryColor, Color cardColor, Color borderColor, Color mutedForeground, TranslationService ts, Map<String, dynamic>? request) {
    final title = request != null ? '${request['make']} ${request['model']}' : 'Mercedes-Benz GLE 450';
    final id = request != null ? '#${request['id'].toString().substring(0, 4).toUpperCase()}' : '#4920';
    final budget = request != null ? (request['budget_max'] ?? 0).toDouble() : 45000000.0;
    final year = request != null ? '${request['year_min']} - ${request['year_max']}' : '2021 - 2023';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overview Section
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: cardColor.withOpacity(0.4),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: borderColor.withOpacity(0.6)),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -20,
                right: -20,
                child: Opacity(
                  opacity: 0.05,
                  child: Icon(Icons.workspace_premium_rounded, size: 120, color: primaryColor),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: GoogleFonts.montserrat(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildBadge('RECHERCHE CARTEL', primaryColor, primaryColor.withValues(alpha: 0.1)),
                                  _buildBadge(id, mutedForeground, const Color(0xFF1F1F1F)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: primaryColor.withOpacity(0.3)),
                                boxShadow: [
                                  BoxShadow(color: primaryColor.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 4)),
                                ],
                              ),
                              child: _SpinningRefreshIcon(color: primaryColor),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'EN RECHERCHE',
                              style: GoogleFonts.plusJakartaSans(
                                color: primaryColor,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(height: 1, color: borderColor.withOpacity(0.2)),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoItem(ts.translate('budget_prevu'), ts.formatPrice(budget), primaryColor, mutedForeground),
                        ),
                        Expanded(
                          child: _buildInfoItem(ts.translate('periode'), year, Colors.white, mutedForeground),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Status Timeline
        _buildSectionTitle(ts.translate('statut').toUpperCase() + ' DU DOSSIER', mutedForeground),
        const SizedBox(height: 16),
        _buildTimeline(primaryColor, cardColor, borderColor, mutedForeground, ts, request),

        const SizedBox(height: 32),

        // Agent Section
        if (request?['agent_id'] != null) ...[
          _buildSectionTitle(ts.translate('agent_responsable').toUpperCase(), mutedForeground),
          const SizedBox(height: 16),
          _buildAgentCard(context, primaryColor, cardColor, borderColor, mutedForeground, ts, request),
        ],

        const SizedBox(height: 32),

        // Action Button
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            label: Text('ANNULER LA DEMANDE'.toUpperCase()),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF1F1F1F),
              foregroundColor: mutedForeground,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: borderColor.withOpacity(0.5)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFoundLayout(BuildContext context, Color primaryColor, Color cardColor, Color borderColor, Color mutedForeground, TranslationService ts, Map<String, dynamic>? request) {
    final title = request != null ? '${request['make']} ${request['model']}' : 'Mercedes-Benz GLE 450';
    final id = request != null ? '#${request['id'].toString().substring(0, 4).toUpperCase()}' : '#4920';
    final budget = request != null ? (request['budget_max'] ?? 0).toDouble() : 45000000.0;
    final year = request != null ? '${request['year_min']} - ${request['year_max']}' : '2021 - 2023';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overview Section (Modified for "Found" state)
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: cardColor.withOpacity(0.4),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: borderColor.withOpacity(0.6)),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -20,
                right: -20,
                child: Opacity(
                  opacity: 0.1,
                  child: Icon(Icons.stars_rounded, size: 120, color: primaryColor),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: GoogleFonts.montserrat(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _buildBadge('STANDARD', primaryColor, primaryColor.withOpacity(0.1)),
                                  const SizedBox(width: 8),
                                  _buildBadge(id, mutedForeground, const Color(0xFF1F1F1F)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.green.withOpacity(0.3)),
                                boxShadow: [
                                  BoxShadow(color: Colors.green.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 4)),
                                ],
                              ),
                              child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'TROUVÉ',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.green,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(height: 1, color: borderColor.withOpacity(0.2)),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoItem(ts.translate('budget_prevu'), ts.formatPrice(budget), primaryColor, mutedForeground),
                        ),
                        Expanded(
                          child: _buildInfoItem(ts.translate('periode'), year, Colors.white, mutedForeground),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Matches Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('${ts.translate('matches_trouves')} (${_matches.length.toString().padLeft(2, '0')})', mutedForeground),
            Text(
              ts.translate('voir_tout'),
              style: GoogleFonts.plusJakartaSans(
                color: primaryColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isLoadingMatches)
          Center(child: Padding(padding: const EdgeInsets.all(20), child: CircularProgressIndicator(color: primaryColor)))
        else if (_matches.isEmpty)
          Center(child: Text('Aucun match trouvé', style: GoogleFonts.plusJakartaSans(color: mutedForeground)))
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _matches.length,
            separatorBuilder: (context, index) => const SizedBox(height: 24),
            itemBuilder: (context, index) {
              final match = _matches[index];
              return _buildMatchCardNew(context, match, primaryColor, borderColor, mutedForeground, ts, budgetMax: budget, request: _request);
            },
          ),

        const SizedBox(height: 32),

        // Agent Section
        if (request?['agent_id'] != null) ...[
          _buildSectionTitle(ts.translate('agent_responsable').toUpperCase(), mutedForeground),
          const SizedBox(height: 16),
          _buildAgentCard(context, primaryColor, cardColor, borderColor, mutedForeground, ts, request),
        ],
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildMatchCardNew(BuildContext context, Map<String, dynamic> match, Color primaryColor, Color borderColor, Color mutedForeground, TranslationService ts, {required double budgetMax, Map<String, dynamic>? request}) {
    final title = '${match['make']} ${match['model']}';
    final price = (match['final_price'] ?? 0).toDouble();
    final priceStr = ts.formatPrice(price);
    final subtitle = '${match['year']} • ${match['mileage']?.toString() ?? '0'} KM • ${match['engine'] ?? 'Essence'}';
    final imageUrl = (match['image_urls'] != null && match['image_urls'] is List && (match['image_urls'] as List).isNotEmpty)
        ? (match['image_urls'] as List).first.toString()
        : 'https://ggrhecslgdflloszjkwl.supabase.co/storage/v1/object/public/user-assets/rRHZ5DOPVSb/components/Xxui1AANB7v.png';

    final isOverBudget = price > budgetMax;
    final isTopMatch = match['status'] == 'top_match'; // For demo, we can assume a status or add a flag

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/car-details',
          arguments: {
            ...match,
            'is_match': true,
            'agents': request?['agents'],
          },
        );
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF141414).withOpacity(0.4),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: borderColor.withOpacity(0.6)),
      ),
      child: Column(
        children: [
          // Image Area
          Stack(
            children: [
              Image.network(
                imageUrl,
                height: 192,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 192,
                  color: Colors.white.withOpacity(0.05),
                  child: const Icon(Icons.directions_car_rounded, color: Colors.white24, size: 48),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A0A).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: borderColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    priceStr,
                    style: GoogleFonts.plusJakartaSans(
                      color: primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (isTopMatch)
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'TOP MATCH',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.black,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              if (isOverBudget)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.4),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Text(
                          'HORS BUDGET',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          // Content Area
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    color: mutedForeground,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: isOverBudget ? null : () {},
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.green.withOpacity(isOverBudget ? 0.05 : 0.15),
                          foregroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.green.withOpacity(isOverBudget ? 0.1 : 0.3)),
                          ),
                        ),
                        child: Text(
                          ts.translate('accepter').toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.1),
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.red.withOpacity(0.2)),
                          ),
                        ),
                        child: Text(
                          ts.translate('refuser').toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildInfoItem(String label, String value, Color valueColor, Color labelColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.plusJakartaSans(
            color: labelColor,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.montserrat(
            color: valueColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: GoogleFonts.montserrat(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildTimeline(Color primaryColor, Color cardColor, Color borderColor, Color mutedForeground, TranslationService ts, Map<String, dynamic>? request) {
    final agentData = request?['agents'];
    final agentId = request?['agent_id'];
    final agentAssigned = agentId != null;
    final status = request?['status']?.toString().toLowerCase() ?? 'initialisée';
    final isInProgress = status == 'en cours' || status == 'en_cours';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: borderColor.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          _buildTimelineItem(
            'Paiement Validé', 
            '12 Oct 2023, 10:45', 
            Colors.green, 
            true, 
            true, 
            backgroundColor: const Color(0xFF0A0A0A)
          ),
          _buildTimelineItem(
            'Agent Assigné', 
            agentAssigned ? (agentData?['name'] ?? 'Jean-Paul Moukoko') : 'En attente d\'assignation...', 
            agentAssigned ? Colors.green : const Color(0xFF1F1F1F), 
            agentAssigned, 
            true, 
            backgroundColor: const Color(0xFF0A0A0A)
          ),
          _buildTimelineItem(
            'Recherche Active', 
            agentAssigned ? 'Identification des véhicules en cours...' : 'En attente...', 
            (agentAssigned && isInProgress) ? primaryColor : const Color(0xFF1F1F1F), 
            agentAssigned && isInProgress, 
            true, 
            isPulse: agentAssigned && isInProgress, 
            backgroundColor: const Color(0xFF0A0A0A)
          ),
          _buildTimelineItem(
            'Rapport Final', 
            'En attente de résultats', 
            const Color(0xFF1F1F1F), 
            false, 
            false, 
            backgroundColor: const Color(0xFF0A0A0A)
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String title, String subtitle, Color color, bool isCompleted, bool showLine, {bool isPulse = false, required Color backgroundColor}) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: backgroundColor, width: 2),
                  boxShadow: [
                    if (isCompleted || isPulse)
                      BoxShadow(color: color.withOpacity(0.4), blurRadius: 10),
                  ],
                ),
                child: isPulse ? _PulseCircle(color: color) : null,
              ),
              if (showLine)
                Expanded(
                  child: Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: const Color(0xFF2A2A2A).withOpacity(0.6),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    color: isCompleted ? Colors.white : color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFFA3A3A3),
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentCard(BuildContext context, Color primaryColor, Color cardColor, Color borderColor, Color mutedForeground, TranslationService ts, Map<String, dynamic>? request) {
    final agentData = request?['agents'];
    final agentName = agentData?['name'] ?? 'Agent CarTel';
    final agentPhotoUrl = agentData?['avatar_url'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: primaryColor.withOpacity(0.3), width: 2),
              image: DecorationImage(
                image: (agentPhotoUrl != null && agentPhotoUrl.toString().isNotEmpty)
                    ? NetworkImage(agentPhotoUrl.toString())
                    : const NetworkImage('https://randomuser.me/api/portraits/men/12.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      agentName,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.verified_rounded, color: Colors.blue, size: 14),
                  ],
                ),
                Text(
                  'Expert Mercedes & Luxe • Actif',
                  style: GoogleFonts.plusJakartaSans(
                    color: mutedForeground,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.black, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withOpacity(0.2)),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          color: textColor,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _SpinningRefreshIcon extends StatefulWidget {
  final Color color;
  const _SpinningRefreshIcon({required this.color});

  @override
  State<_SpinningRefreshIcon> createState() => _SpinningRefreshIconState();
}

class _SpinningRefreshIconState extends State<_SpinningRefreshIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Icon(Icons.refresh_rounded, color: widget.color, size: 28),
    );
  }
}

class _PulseCircle extends StatefulWidget {
  final Color color;
  const _PulseCircle({required this.color});

  @override
  State<_PulseCircle> createState() => _PulseCircleState();
}

class _PulseCircleState extends State<_PulseCircle> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
