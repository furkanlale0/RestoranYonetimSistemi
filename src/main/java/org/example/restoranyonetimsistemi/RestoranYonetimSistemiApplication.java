package org.example.restoranyonetimsistemi;

import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;

import javax.sql.DataSource;
import java.sql.Connection;

@SpringBootApplication
public class RestoranYonetimSistemiApplication {

    public static void main(String[] args) {
        SpringApplication.run(RestoranYonetimSistemiApplication.class, args);
    }

    @Bean
    public CommandLineRunner testConnection(DataSource dataSource) {
        return args -> {
            try (Connection connection = dataSource.getConnection()) {
                System.out.println("✅ BAĞLANTI BAŞARILI: " + connection.getMetaData().getDatabaseProductName());
                System.out.println("🚀 Restoran sistemi veritabanına başarıyla bağlandı!");
            } catch (Exception e) {
                System.err.println("❌ BAĞLANTI HATASI: Veritabanına ulaşılamadı!");
                System.err.println("Hata Detayı: " + e.getMessage());
            }
        };
    }
}