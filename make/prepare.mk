class.list: dependencies/class-exclude.grep dependencies/hppc/target/generated-sources j2objc
	find graphhopper/core/src/main/java graphhopper/api/src/main/java dependencies/hppc/hppc/src/main/java dependencies/hppc/hppc/target/generated-sources  dependencies/jackson-annotations dependencies/jts/modules/core/src/main/java -name '*.java' | grep -vf dependencies/class-exclude.grep > $@
	find dependencies/fake_slf4j/src -name '*.java' >> $@

j2objc:
	@echo "warning: 'j2objc' doesn't exist and needs to be downloaded, \
this may take some time... To skip this, manually place the j2objc dist directory at /graphhopper-ios/j2objc."
	@curl -L -o j2objc-2.5.zip "https://github.com/google/j2objc/releases/download/2.5/j2objc-2.5.zip"; \
	unzip j2objc-2.5.zip; \
	mv j2objc-2.5 j2objc; \
	rm j2objc-2.5.zip

dependencies/hppc/target/generated-sources :
	bash -c "cd dependencies/hppc; mvn generate-sources"
