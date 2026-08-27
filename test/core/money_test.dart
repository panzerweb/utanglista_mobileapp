import 'package:flutter_test/flutter_test.dart';
import 'package:utanglista_mobileapp/core/money/money.dart';

/*
  These tests exist because the failures they guard against are silent.
  A centavo of drift does not crash anything — it just makes the app
  tell a store owner that a customer who paid in full still owes ₱0.01,
  and there is no way for them to tell that it is wrong.
*/
void main() {
  group('construction', () {
    test('fromPesos converts to centavos', () {
      expect(Money.fromPesos(1250.75).centavos, 125075);
      expect(Money.fromPesos(100).centavos, 10000);
      expect(Money.fromPesos(0.5).centavos, 50);
    });

    test('zero is zero', () {
      expect(Money.zero.centavos, 0);
      expect(Money.zero.isZero, isTrue);
    });
  });

  group('parsing', () {
    test('accepts plain and decorated input', () {
      expect(Money.parse('1250.75').centavos, 125075);
      expect(Money.parse('₱1,250.75').centavos, 125075);
      expect(Money.parse(' 1250.75 ').centavos, 125075);
      expect(Money.parse('100').centavos, 10000);
    });

    test('pads the fraction on the right, not the left', () {
      // '5.5' is fifty centavos, not five.
      expect(Money.parse('5.5').centavos, 550);
      expect(Money.parse('5.05').centavos, 505);
      expect(Money.parse('.5').centavos, 50);
    });

    test('survives the values that break double parsing', () {
      // 0.29 * 100 == 28.999999999999996 in binary floating point.
      expect(Money.parse('0.29').centavos, 29);
      expect(Money.parse('1.15').centavos, 115);
      expect(Money.parse('8.20').centavos, 820);
      expect(Money.parse('1234567.89').centavos, 123456789);
    });

    test('rejects what is not an amount', () {
      expect(Money.tryParse(''), isNull);
      expect(Money.tryParse('abc'), isNull);
      expect(Money.tryParse('.'), isNull);
      expect(Money.tryParse('1.2.3'), isNull);
      expect(Money.tryParse('12.345'), isNull); // more precision than a centavo
    });

    test('handles negatives so a parser bug cannot mask one', () {
      expect(Money.parse('-50.25').centavos, -5025);
      expect(Money.parse('-50.25').isNegative, isTrue);
    });
  });

  group('arithmetic', () {
    test('addition is exact where double addition is not', () {
      // The canonical 0.1 + 0.2 != 0.3 failure, in pesos.
      final result = Money.fromPesos(0.1) + Money.fromPesos(0.2);
      expect(result, Money.fromPesos(0.3));
      expect(result.centavos, 30);
    });

    test('a long ledger does not drift', () {
      // 1000 additions of ₱0.01 is exactly ₱10.00, not 9.999999999.
      var total = Money.zero;
      for (var i = 0; i < 1000; i++) {
        total = total + Money.fromCentavos(1);
      }
      expect(total, Money.fromPesos(10));
    });

    test('subtraction reaches exactly zero', () {
      // This is the comparison the whole app leans on: fully paid.
      final balance = Money.fromPesos(540.60) - Money.fromPesos(540.60);
      expect(balance.isZero, isTrue);
    });

    test('sum extension folds a list', () {
      final items = [
        Money.fromPesos(500),
        Money.fromPesos(40),
        Money.fromPesos(90),
      ];
      expect(items.sum(), Money.fromPesos(630));
    });

    test('sum of an empty list is zero', () {
      expect(<Money>[].sum(), Money.zero);
    });
  });

  group('multiplication by quantity', () {
    test('whole quantities are exact', () {
      // 5 × ₱100 = ₱500, the §7 worked example.
      expect(Money.fromPesos(100) * 5, Money.fromPesos(500));
      expect(Money.fromPesos(20) * 2, Money.fromPesos(40));
      expect(Money.fromPesos(30) * 3, Money.fromPesos(90));
    });

    test('fractional quantities round once, half away from zero', () {
      // 1.5 kg at ₱99.99 = ₱149.985 -> ₱149.99
      expect(Money.fromPesos(99.99) * 1.5, Money.fromCentavos(14999));
      // 0.5 × ₱0.05 = ₱0.025 -> ₱0.03
      expect(Money.fromCentavos(5) * 0.5, Money.fromCentavos(3));
    });

    test('zero quantity yields zero', () {
      expect(Money.fromPesos(100) * 0, Money.zero);
    });
  });

  group('interest by basis points', () {
    test('applies the §20 worked example', () {
      // ₱1,000.00 at 2% = ₱20.00
      expect(
        Money.fromPesos(1000).applyRateBasisPoints(200),
        Money.fromPesos(20),
      );
    });

    test('applies the §36 worked example', () {
      // ₱530.00 at 2% = ₱10.60
      expect(
        Money.fromPesos(530).applyRateBasisPoints(200),
        Money.fromPesos(10.60),
      );
    });

    test('the §19 cap of 5% is an exact integer', () {
      expect(
        Money.fromPesos(1000).applyRateBasisPoints(500),
        Money.fromPesos(50),
      );
    });

    test('zero rate charges nothing', () {
      expect(Money.fromPesos(1000).applyRateBasisPoints(0), Money.zero);
    });

    test('rounds to the centavo', () {
      // ₱333.33 at 2% = ₱6.6666 -> ₱6.67
      expect(
        Money.fromPesos(333.33).applyRateBasisPoints(200),
        Money.fromCentavos(667),
      );
    });
  });

  group('comparison', () {
    test('orders correctly', () {
      expect(Money.fromPesos(100) > Money.fromPesos(50), isTrue);
      expect(Money.fromPesos(50) < Money.fromPesos(100), isTrue);
      expect(Money.fromPesos(100) >= Money.fromPesos(100), isTrue);
      expect(Money.fromPesos(100) <= Money.fromPesos(100), isTrue);
    });

    test('equality is by value', () {
      expect(Money.fromPesos(100), Money.fromCentavos(10000));
      expect(Money.fromPesos(100).hashCode, Money.fromCentavos(10000).hashCode);
    });

    test('sorts as money, not as text', () {
      final amounts = [
        Money.fromPesos(100),
        Money.fromPesos(5),
        Money.fromPesos(20),
      ]..sort();
      expect(amounts.map((m) => m.centavos), [500, 2000, 10000]);
    });
  });

  group('formatting', () {
    test('renders pesos with separators and two decimals', () {
      expect(Money.fromPesos(1250.75).format(), '₱1,250.75');
      expect(Money.fromPesos(500).format(), '₱500.00');
      expect(Money.zero.format(), '₱0.00');
    });

    test('plain form drops the symbol but keeps separators', () {
      expect(Money.fromPesos(1250.75).formatPlain(), '1,250.75');
    });

    test('editable form drops separators for text input', () {
      expect(Money.fromPesos(1250.75).toEditableString(), '1250.75');
    });

    test('round-trips through parse', () {
      final original = Money.fromPesos(1250.75);
      expect(Money.parse(original.toEditableString()), original);
      expect(Money.parse(original.format()), original);
    });
  });

  /*
    The §36 scenario end to end. If this ever fails, the accounting
    model has drifted from the business rules, not just the arithmetic.
  */
  group('transaction_logic.md §36 scenario', () {
    test('Juan ends the month owing ₱540.60', () {
      final day1 = Money.fromPesos(100) * 5; // 5 × Rice   = ₱500.00
      final day2 = Money.fromPesos(20) * 2; // 2 × Coffee  = ₱40.00
      final day3 = Money.fromPesos(100); // payment        = ₱100.00
      final day4 = Money.fromPesos(30) * 3; // 3 × Sardines= ₱90.00

      expect(day1, Money.fromPesos(500));
      expect(day2, Money.fromPesos(40));
      expect(day4, Money.fromPesos(90));

      // balance = Σ transactions − Σ payments  (§15)
      final beforeInterest = [day1, day2, day4].sum() - day3;
      expect(beforeInterest, Money.fromPesos(530));

      final interest = beforeInterest.applyRateBasisPoints(200); // 2%
      expect(interest, Money.fromPesos(10.60));

      final finalBalance = beforeInterest + interest;
      expect(finalBalance, Money.fromPesos(540.60));
      expect(finalBalance.format(), '₱540.60');
    });
  });
}
