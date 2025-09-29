import 'package:flutter/material.dart';

enum PeriodType { monthly, quarterly }

class PeriodPickerWidget extends StatefulWidget {
  final DateTime selectedPeriod;
  final PeriodType periodType;
  final Function(DateTime) onPeriodChanged;
  final Function(PeriodType) onPeriodTypeChanged;

  const PeriodPickerWidget({
    super.key,
    required this.selectedPeriod,
    required this.periodType,
    required this.onPeriodChanged,
    required this.onPeriodTypeChanged,
  });

  @override
  State<PeriodPickerWidget> createState() => _PeriodPickerWidgetState();
}

class _PeriodPickerWidgetState extends State<PeriodPickerWidget> {
  late PageController _pageController;
  late DateTime _currentDate;

  @override
  void initState() {
    super.initState();
    _currentDate = widget.selectedPeriod;
    _pageController = PageController(initialPage: 1000); // Start au milieu pour permettre navigation dans les deux sens
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // En-tête avec sélecteur de type
          _buildTypeSelector(theme),
          const SizedBox(height: 16),

          // Navigation de période
          _buildPeriodNavigation(theme),
          const SizedBox(height: 16),

          // Calendrier/sélecteur rapide
          _buildQuickSelector(theme),
        ],
      ),
    );
  }

  Widget _buildTypeSelector(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTypeButton(
              theme,
              'Mensuel',
              Icons.calendar_month,
              PeriodType.monthly,
              widget.periodType == PeriodType.monthly,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
          Expanded(
            child: _buildTypeButton(
              theme,
              'Trimestriel',
              Icons.calendar_view_month,
              PeriodType.quarterly,
              widget.periodType == PeriodType.quarterly,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(
    ThemeData theme,
    String label,
    IconData icon,
    PeriodType type,
    bool isSelected,
  ) {
    return Material(
      color: isSelected
          ? theme.colorScheme.primary.withOpacity(0.1)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => widget.onPeriodTypeChanged(type),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.8),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodNavigation(ThemeData theme) {
    final displayText = widget.periodType == PeriodType.monthly
        ? _getMonthDisplay(_currentDate)
        : _getQuarterDisplay(_currentDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Bouton précédent
          IconButton(
            onPressed: _goToPrevious,
            icon: Icon(
              Icons.chevron_left,
              color: theme.colorScheme.primary,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.transparent,
              padding: const EdgeInsets.all(8),
            ),
          ),

          // Période actuelle
          Expanded(
            child: GestureDetector(
              onTap: _showPeriodPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      displayText,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.expand_more,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bouton suivant
          IconButton(
            onPressed: _goToNext,
            icon: Icon(
              Icons.chevron_right,
              color: theme.colorScheme.primary,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.transparent,
              padding: const EdgeInsets.all(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSelector(ThemeData theme) {
    final now = DateTime.now();
    final currentYear = now.year;

    if (widget.periodType == PeriodType.monthly) {
      return _buildMonthGrid(theme, currentYear);
    } else {
      return _buildQuarterGrid(theme, currentYear);
    }
  }

  Widget _buildMonthGrid(ThemeData theme, int year) {
    const monthNames = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
      'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'
    ];

    return Column(
      children: [
        // Sélecteur d'année
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () => _changeYear(year - 1),
              icon: const Icon(Icons.chevron_left, size: 20),
            ),
            Text(
              year.toString(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            IconButton(
              onPressed: () => _changeYear(year + 1),
              icon: const Icon(Icons.chevron_right, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Grille des mois
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.5,
          ),
          itemCount: 12,
          itemBuilder: (context, index) {
            final month = index + 1;
            final isSelected = _currentDate.year == year && _currentDate.month == month;
            final isCurrent = DateTime.now().year == year && DateTime.now().month == month;

            return _buildPeriodChip(
              theme,
              monthNames[index],
              isSelected,
              isCurrent,
              () => _selectMonth(year, month),
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuarterGrid(ThemeData theme, int year) {
    const quarterNames = ['Q1', 'Q2', 'Q3', 'Q4'];

    return Column(
      children: [
        // Sélecteur d'année
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () => _changeYear(year - 1),
              icon: const Icon(Icons.chevron_left, size: 20),
            ),
            Text(
              year.toString(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            IconButton(
              onPressed: () => _changeYear(year + 1),
              icon: const Icon(Icons.chevron_right, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Grille des trimestres
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 3,
          ),
          itemCount: 4,
          itemBuilder: (context, index) {
            final quarter = index + 1;
            final isSelected = _currentDate.year == year &&
                ((_currentDate.month - 1) ~/ 3) + 1 == quarter;
            final currentQuarter = ((DateTime.now().month - 1) ~/ 3) + 1;
            final isCurrent = DateTime.now().year == year && currentQuarter == quarter;

            return _buildPeriodChip(
              theme,
              quarterNames[index],
              isSelected,
              isCurrent,
              () => _selectQuarter(year, quarter),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPeriodChip(
    ThemeData theme,
    String label,
    bool isSelected,
    bool isCurrent,
    VoidCallback onTap,
  ) {
    return Material(
      color: isSelected
          ? theme.colorScheme.primary
          : isCurrent
              ? theme.colorScheme.secondary.withOpacity(0.1)
              : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(8),
      elevation: isSelected ? 2 : 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isCurrent && !isSelected
                  ? theme.colorScheme.secondary
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected
                    ? Colors.white
                    : isCurrent
                        ? theme.colorScheme.secondary
                        : theme.colorScheme.onSurface,
                fontWeight: isSelected || isCurrent ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _goToPrevious() {
    setState(() {
      if (widget.periodType == PeriodType.monthly) {
        _currentDate = DateTime(_currentDate.year, _currentDate.month - 1, 1);
      } else {
        final currentQuarter = ((_currentDate.month - 1) ~/ 3) + 1;
        final previousQuarter = currentQuarter - 1;

        if (previousQuarter < 1) {
          _currentDate = DateTime(_currentDate.year - 1, 10, 1); // Q4 année précédente
        } else {
          final newMonth = (previousQuarter - 1) * 3 + 1;
          _currentDate = DateTime(_currentDate.year, newMonth, 1);
        }
      }
    });
    widget.onPeriodChanged(_currentDate);
  }

  void _goToNext() {
    setState(() {
      if (widget.periodType == PeriodType.monthly) {
        _currentDate = DateTime(_currentDate.year, _currentDate.month + 1, 1);
      } else {
        final currentQuarter = ((_currentDate.month - 1) ~/ 3) + 1;
        final nextQuarter = currentQuarter + 1;

        if (nextQuarter > 4) {
          _currentDate = DateTime(_currentDate.year + 1, 1, 1); // Q1 année suivante
        } else {
          final newMonth = (nextQuarter - 1) * 3 + 1;
          _currentDate = DateTime(_currentDate.year, newMonth, 1);
        }
      }
    });
    widget.onPeriodChanged(_currentDate);
  }

  void _selectMonth(int year, int month) {
    setState(() {
      _currentDate = DateTime(year, month, 1);
    });
    widget.onPeriodChanged(_currentDate);
  }

  void _selectQuarter(int year, int quarter) {
    final month = (quarter - 1) * 3 + 1;
    setState(() {
      _currentDate = DateTime(year, month, 1);
    });
    widget.onPeriodChanged(_currentDate);
  }

  void _changeYear(int newYear) {
    setState(() {
      if (widget.periodType == PeriodType.monthly) {
        _currentDate = DateTime(newYear, _currentDate.month, 1);
      } else {
        final currentQuarter = ((_currentDate.month - 1) ~/ 3) + 1;
        final newMonth = (currentQuarter - 1) * 3 + 1;
        _currentDate = DateTime(newYear, newMonth, 1);
      }
    });
    widget.onPeriodChanged(_currentDate);
  }

  void _showPeriodPicker() {
    showDatePicker(
      context: context,
      initialDate: _currentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    ).then((date) {
      if (date != null) {
        setState(() {
          _currentDate = DateTime(date.year, date.month, 1);
        });
        widget.onPeriodChanged(_currentDate);
      }
    });
  }

  String _getMonthDisplay(DateTime date) {
    const months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _getQuarterDisplay(DateTime date) {
    final quarter = ((date.month - 1) ~/ 3) + 1;
    return 'Q$quarter ${date.year}';
  }
}