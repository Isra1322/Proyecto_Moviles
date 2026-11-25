import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:ecommerce_app/core/constants/app_colors.dart';
import 'package:ecommerce_app/core/theme/app_theme.dart';
import 'package:ecommerce_app/infrastructure/datasources/remote/address_service.dart';
import 'package:ecommerce_app/infrastructure/datasources/remote/payment_service.dart';
import 'package:ecommerce_app/infrastructure/models/address_model.dart';
import 'package:ecommerce_app/infrastructure/models/payment_method_model.dart';
import 'package:ecommerce_app/presentation/providers/address_provider.dart';
import 'package:ecommerce_app/presentation/providers/payment_provider.dart';
import 'package:ecommerce_app/presentation/widgets/address/add_edit_address_modal.dart';
import 'package:ecommerce_app/presentation/widgets/address/select_address_modal.dart';
import 'package:ecommerce_app/presentation/widgets/payment/add_card_modal.dart';
import 'package:ecommerce_app/presentation/widgets/payment/select_card_modal.dart';

class _MockPaymentService implements PaymentService {
  List<PaymentMethodModel> methods;
  _MockPaymentService(this.methods);

  @override
  Future<List<PaymentMethodModel>> getPaymentMethods() async => List.from(methods);

  @override
  Future<PaymentMethodModel> addPaymentMethod({
    required String cardNumber,
    required String cardHolderName,
    required String expiryDate,
    required String cvv,
    bool isDefault = false,
  }) async =>
      throw UnimplementedError();

  @override
  Future<bool> deletePaymentMethod(String id) async => true;

  @override
  Future<Map<String, dynamic>> createPaymentIntent({
    required double amount,
    String currency = 'usd',
    String? customerEmail,
    String? customerName,
  }) async =>
      {
        'clientSecret': 'pi_test_secret_123',
        'paymentIntentId': 'pi_test_123456789',
        'customerId': 'cus_test_123',
        'ephemeralKeySecret': 'ek_test_secret_123',
        'publishableKey': 'pk_test_mock',
      };
}

class _MockAddressService implements AddressService {
  List<AddressModel> addresses;
  _MockAddressService(this.addresses);

  @override
  Future<List<AddressModel>> getAddresses() async => List.from(addresses);

  @override
  Future<AddressModel> createAddress({
    required String title,
    required String street,
    required String city,
    String stateOrProvince = '',
    String? postalCode,
    String? reference,
    required String phone,
    bool isDefault = false,
  }) async =>
      throw UnimplementedError();

  @override
  Future<AddressModel> updateAddress({
    required String id,
    required String title,
    required String street,
    required String city,
    String stateOrProvince = '',
    String? postalCode,
    String? reference,
    required String phone,
    bool isDefault = false,
  }) async =>
      throw UnimplementedError();

  @override
  Future<bool> deleteAddress(String id) async => true;

  @override
  Future<AddressModel> setDefaultAddress(String id) async => addresses.first;
}

void main() {
  final sampleCard1 = PaymentMethodModel(
    id: 'card-1',
    partnerId: 1,
    cardHolderName: 'SEBAS',
    maskedCardNumber: '**** **** **** 4242',
    cardType: 'Visa',
    expiryDate: '10/27',
    isDefault: true,
    createdAt: DateTime.now(),
  );

  final sampleCard2 = PaymentMethodModel(
    id: 'card-2',
    partnerId: 1,
    cardHolderName: 'SEBAS',
    maskedCardNumber: '**** **** **** 5555',
    cardType: 'MasterCard',
    expiryDate: '12/28',
    isDefault: false,
    createdAt: DateTime.now(),
  );

  final sampleAddress1 = AddressModel(
    id: 'addr-1',
    partnerId: 1,
    title: 'Atocha',
    street: 'El Sol',
    city: 'Ambato',
    stateOrProvince: 'Tungurahua',
    reference: 'Casa Ploma',
    phone: '0991234567',
    isDefault: true,
    createdAt: DateTime.now(),
  );

  final sampleAddress2 = AddressModel(
    id: 'addr-2',
    partnerId: 1,
    title: 'Oficina',
    street: 'Av. Amazonas y Colón',
    city: 'Quito',
    stateOrProvince: 'Pichincha',
    phone: '0987654321',
    isDefault: false,
    createdAt: DateTime.now(),
  );

  group('SelectCardModal Dark Mode & Light Mode Tests', () {
    testWidgets('SelectCardModal renders correctly in Dark Mode', (tester) async {
      final paymentService = _MockPaymentService([sampleCard1, sampleCard2]);
      final paymentProvider = PaymentProvider(paymentService);
      await paymentProvider.loadPaymentMethods();
      paymentProvider.selectMethod(sampleCard1);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: paymentProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const Scaffold(
              body: SelectCardModal(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Título: "Seleccionar Método de Pago" en color blanco
      final titleFinder = find.text('Seleccionar Método de Pago');
      expect(titleFinder, findsOneWidget);
      final titleText = tester.widget<Text>(titleFinder);
      expect(titleText.style?.color, equals(Colors.white));

      // 2. Botón Cerrar (X): ícono en color Colors.white70
      final closeIconFinder = find.byIcon(Icons.close);
      expect(closeIconFinder, findsOneWidget);
      final closeIcon = tester.widget<Icon>(closeIconFinder);
      expect(closeIcon.color, equals(Colors.white70));

      // 3. Tarjeta de la tarjeta seleccionada
      final cardTitleFinder = find.text('**** **** **** 4242');
      expect(cardTitleFinder, findsOneWidget);
      final cardTitle = tester.widget<Text>(cardTitleFinder);
      expect(cardTitle.style?.color, equals(Colors.white));

      final cardSubtitleFinder = find.text('SEBAS • Exp: 10/27');
      expect(cardSubtitleFinder, findsOneWidget);
      final cardSubtitle = tester.widget<Text>(cardSubtitleFinder);
      expect(cardSubtitle.style?.color, equals(const Color(0xFFB0B0B0)));

      // 4. Botón "+ Agregar otra tarjeta": borde azul con texto e ícono azul primario
      final addBtnFinder = find.text('Agregar otra tarjeta');
      expect(addBtnFinder, findsOneWidget);
      final addBtnText = tester.widget<Text>(addBtnFinder);
      expect(addBtnText.style?.color, equals(const Color(0xFF2196F3)));
    });

    testWidgets('SelectCardModal renders correctly in Light Mode', (tester) async {
      final paymentService = _MockPaymentService([sampleCard1]);
      final paymentProvider = PaymentProvider(paymentService);
      await paymentProvider.loadPaymentMethods();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: paymentProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: SelectCardModal(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final titleFinder = find.text('Seleccionar Método de Pago');
      expect(titleFinder, findsOneWidget);
      final titleText = tester.widget<Text>(titleFinder);
      expect(titleText.style?.color, equals(AppColors.textPrimary));

      final closeIconFinder = find.byIcon(Icons.close);
      expect(closeIconFinder, findsOneWidget);
      final closeIcon = tester.widget<Icon>(closeIconFinder);
      expect(closeIcon.color, equals(Colors.black54));
    });
  });

  group('SelectAddressModal Dark Mode & Light Mode Tests', () {
    testWidgets('SelectAddressModal renders correctly in Dark Mode', (tester) async {
      final addressService = _MockAddressService([sampleAddress1, sampleAddress2]);
      final addressProvider = AddressProvider(addressService);
      await addressProvider.loadAddresses();
      addressProvider.selectAddress(sampleAddress1);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: addressProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const Scaffold(
              body: SelectAddressModal(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Título: "Dirección de Entrega" en color blanco
      final titleFinder = find.text('Dirección de Entrega');
      expect(titleFinder, findsOneWidget);
      final titleText = tester.widget<Text>(titleFinder);
      expect(titleText.style?.color, equals(Colors.white));

      // 2. Botón Cerrar (X): ícono en color Colors.white70
      final closeIconFinder = find.byIcon(Icons.close);
      expect(closeIconFinder, findsOneWidget);
      final closeIcon = tester.widget<Icon>(closeIconFinder);
      expect(closeIcon.color, equals(Colors.white70));

      // 3. Tarjeta de Dirección:
      // Alias ("Atocha"): texto en blanco
      final aliasFinder = find.text('Atocha');
      expect(aliasFinder, findsOneWidget);
      final aliasText = tester.widget<Text>(aliasFinder);
      expect(aliasText.style?.color, equals(Colors.white));

      // Chip "Predeterminada": texto legible Color(0xFF90CAF9)
      final badgeFinder = find.text('Predeterminada');
      expect(badgeFinder, findsOneWidget);
      final badgeText = tester.widget<Text>(badgeFinder);
      expect(badgeText.style?.color, equals(const Color(0xFF90CAF9)));

      // Calles, ciudad, referencia y teléfono: Color(0xFFB0B0B0)
      final streetFinder = find.text('El Sol');
      expect(streetFinder, findsOneWidget);
      final streetText = tester.widget<Text>(streetFinder);
      expect(streetText.style?.color, equals(const Color(0xFFB0B0B0)));

      final cityFinder = find.text('Ambato, Tungurahua');
      expect(cityFinder, findsOneWidget);
      final cityText = tester.widget<Text>(cityFinder);
      expect(cityText.style?.color, equals(const Color(0xFFB0B0B0)));

      final refFinder = find.text('Ref: Casa Ploma');
      expect(refFinder, findsOneWidget);
      final refText = tester.widget<Text>(refFinder);
      expect(refText.style?.color, equals(const Color(0xFFB0B0B0)));

      final phoneFinder = find.text('Tel: 0991234567');
      expect(phoneFinder, findsOneWidget);
      final phoneText = tester.widget<Text>(phoneFinder);
      expect(phoneText.style?.color, equals(const Color(0xFFB0B0B0)));

      // 4. Botón "+ Agregar nueva dirección": texto e icono azul primario
      final addBtnFinder = find.text('+ Agregar nueva dirección');
      expect(addBtnFinder, findsOneWidget);
      final addBtnText = tester.widget<Text>(addBtnFinder);
      expect(addBtnText.style?.color, equals(const Color(0xFF2196F3)));
    });

    testWidgets('SelectAddressModal renders correctly in Light Mode', (tester) async {
      final addressService = _MockAddressService([sampleAddress1]);
      final addressProvider = AddressProvider(addressService);
      await addressProvider.loadAddresses();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: addressProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: SelectAddressModal(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final titleFinder = find.text('Dirección de Entrega');
      expect(titleFinder, findsOneWidget);
      final titleText = tester.widget<Text>(titleFinder);
      expect(titleText.style?.color, equals(AppColors.textPrimary));

      final closeIconFinder = find.byIcon(Icons.close);
      expect(closeIconFinder, findsOneWidget);
      final closeIcon = tester.widget<Icon>(closeIconFinder);
      expect(closeIcon.color, equals(Colors.black54));

      final aliasFinder = find.text('Atocha');
      expect(aliasFinder, findsOneWidget);
      final aliasText = tester.widget<Text>(aliasFinder);
      expect(aliasText.style?.color, equals(AppColors.textPrimary));
    });
  });

  group('BottomSheet Opening with Dark Mode Theme Test', () {
    testWidgets('SelectCardModal.show uses dark background in dark theme', (tester) async {
      final paymentService = _MockPaymentService([sampleCard1]);
      final paymentProvider = PaymentProvider(paymentService);
      await paymentProvider.loadPaymentMethods();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: paymentProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Builder(
              builder: (ctx) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => SelectCardModal.show(ctx),
                    child: const Text('Open Modal'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Seleccionar Método de Pago'), findsOneWidget);
      final bottomSheetFinder = find.byType(BottomSheet);
      expect(bottomSheetFinder, findsOneWidget);
      final bottomSheetWidget = tester.widget<BottomSheet>(bottomSheetFinder);
      expect(bottomSheetWidget.backgroundColor, equals(const Color(0xFF1E1E1E)));
    });

    testWidgets('SelectAddressModal.show uses dark background in dark theme', (tester) async {
      final addressService = _MockAddressService([sampleAddress1]);
      final addressProvider = AddressProvider(addressService);
      await addressProvider.loadAddresses();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: addressProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Builder(
              builder: (ctx) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => SelectAddressModal.show(ctx),
                    child: const Text('Open Modal'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Dirección de Entrega'), findsOneWidget);
      final bottomSheetFinder = find.byType(BottomSheet);
      expect(bottomSheetFinder, findsOneWidget);
      final bottomSheetWidget = tester.widget<BottomSheet>(bottomSheetFinder);
      expect(bottomSheetWidget.backgroundColor, equals(const Color(0xFF1E1E1E)));
    });

    testWidgets('AddCardModal renders in Dark Mode with dark surface', (tester) async {
      final paymentService = _MockPaymentService([]);
      final paymentProvider = PaymentProvider(paymentService);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: paymentProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const Scaffold(
              body: AddCardModal(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final titleFinder = find.text('Nueva Tarjeta');
      expect(titleFinder, findsOneWidget);
      final titleWidget = tester.widget<Text>(titleFinder);
      expect(titleWidget.style?.color, equals(Colors.white));

      final closeIcon = tester.widget<Icon>(find.byIcon(Icons.close));
      expect(closeIcon.color, equals(Colors.white70));
    });

    testWidgets('AddEditAddressModal renders in Dark Mode with dark surface', (tester) async {
      final addressService = _MockAddressService([]);
      final addressProvider = AddressProvider(addressService);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: addressProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const Scaffold(
              body: AddEditAddressModal(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final titleFinder = find.text('Nueva Dirección de Entrega');
      expect(titleFinder, findsOneWidget);
      final titleWidget = tester.widget<Text>(titleFinder);
      expect(titleWidget.style?.color, equals(Colors.white));

      final closeIcon = tester.widget<Icon>(find.byIcon(Icons.close));
      expect(closeIcon.color, equals(Colors.white70));
    });
  });
}
